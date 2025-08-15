package utils

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/iam"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

type Policies struct {
	Policies []Policy
}

type Policy struct {
	PolicyName     *string
	PolicyArn      *string
	CreateDate     *time.Time
	UpdateDate     *time.Time
	IsAttachedable string
	LastUsed       time.Time
	UsedBy         string
	Flag           string
	Tags           []Tags
}

type Tags struct {
	Key   *string
	Value *string
}

func IAMClient(cfg aws.Config) *iam.Client {
	iamClient := iam.NewFromConfig(cfg)
	return iamClient
}

// Get the AWS account ID
func GetAccountID(ctx context.Context, cfg aws.Config) (string, error) {
	stsClient := sts.NewFromConfig(cfg)

	output, err := stsClient.GetCallerIdentity(ctx, &sts.GetCallerIdentityInput{})
	if err != nil {
		return "", err
	}

	return *output.Account, nil
}

// Check when a role or user was last used
func GetLastUsed(ctx context.Context, client *iam.Client, accountID string, name string, kind string) (time.Time, error) {
	var arn string

	switch kind {
	case "user":
		arn = fmt.Sprintf("arn:aws:iam::%s:user/%s", accountID, name)
	case "role":
		arn = fmt.Sprintf("arn:aws:iam::%s:role/%s", accountID, name)
	default:
		return time.Time{}, fmt.Errorf("Unknown type: %s", kind)
	}

	// Get usage data for the given ARN
	job, err := client.GenerateServiceLastAccessedDetails(ctx, &iam.GenerateServiceLastAccessedDetailsInput{
		Arn: &arn,
	})
	if err != nil {
		return time.Time{}, err
	}

	// Wait for the job to complete
	for {
		time.Sleep(2 * time.Second)

		result, err := client.GetServiceLastAccessedDetails(ctx, &iam.GetServiceLastAccessedDetailsInput{
			JobId: job.JobId,
		})
		if err != nil {
			return time.Time{}, err
		}

		// If job is finished, get the most recent usage date
		if result.JobStatus == "COMPLETED" {
			latest := time.Time{}
			for _, svc := range result.ServicesLastAccessed {
				if svc.LastAuthenticated != nil && svc.LastAuthenticated.After(latest) {
					latest = *svc.LastAuthenticated
				}
			}
			return latest, nil
		}
	}
}

func ListAllPolicies(iamClient *iam.Client, ctx context.Context) (Policies, error) {
	input := &iam.ListPoliciesInput{
		Scope: "Local",
	}
	var policies Policies

	paginator := iam.NewListPoliciesPaginator(iamClient, input)
	for paginator.HasMorePages() {
		page, err := paginator.NextPage(ctx)
		if err != nil {
			return Policies{}, err
		}
		for _, policy := range page.Policies {
			policies.Policies = append(policies.Policies, Policy{
				PolicyName: policy.PolicyName,
				PolicyArn:  policy.Arn,
				CreateDate: policy.CreateDate,
				UpdateDate: policy.UpdateDate,
			})

			tags, err := ListAllTags(iamClient, ctx, *policy.Arn)
			if err != nil {
				return Policies{}, err
			}
			policies.Policies[len(policies.Policies)-1].Tags = tags
		}
	}
	return policies, nil
}

func ListAllTags(iamClient *iam.Client, ctx context.Context, policyArn string) ([]Tags, error) {
	var tags []Tags

	input := &iam.ListPolicyTagsInput{
		PolicyArn: aws.String(policyArn),
	}

	output, err := iamClient.ListPolicyTags(ctx, input)
	if err != nil {
		return nil, err
	}

	for _, tag := range output.Tags {
		tags = append(tags, Tags{
			Key:   tag.Key,
			Value: tag.Value,
		})
	}

	return tags, nil
}

func GetPolicyLastUsed(iamClient *iam.Client, ctx context.Context, policies Policies, accountID string) ([]Policy, error) {
	var result []Policy
	for _, policy := range policies.Policies {

		entities, err := iamClient.ListEntitiesForPolicy(ctx, &iam.ListEntitiesForPolicyInput{
			PolicyArn: policy.PolicyArn,
		})
		if err != nil {
			fmt.Printf("Error getting entities for policy %s: %v\n", *policy.PolicyName, err)
			continue
		}

		var name, kind string
		var isAttached string
		if len(entities.PolicyUsers) > 0 {
			name = *entities.PolicyUsers[0].UserName
			kind = "user"
			isAttached = "Attached"
		} else if len(entities.PolicyRoles) > 0 {
			name = *entities.PolicyRoles[0].RoleName
			kind = "role"
			isAttached = "Attached"
		} else {
			fmt.Printf("Policy %s is not attached to any users or roles.\n", *policy.PolicyName)
			result = append(result, Policy{
				PolicyName:     policy.PolicyName,
				PolicyArn:      policy.PolicyArn,
				LastUsed:       time.Time{},
				IsAttachedable: "Not Attached",
				UsedBy:         "",
				Flag:           "",
				Tags:           policy.Tags,
			})
			continue
		}

		latestUsed := time.Time{}
		usedBy := ""

		lastUsed, err := GetLastUsed(ctx, iamClient, accountID, name, kind)
		if err != nil {
			fmt.Printf("Error getting last used for %v %s: %v\n", kind, name, err)
			result = append(result, Policy{
				PolicyName:     policy.PolicyName,
				PolicyArn:      policy.PolicyArn,
				LastUsed:       time.Time{},
				IsAttachedable: isAttached,
				UsedBy:         usedBy,
				Flag:           "Error",
				Tags:           policy.Tags,
			})
			continue
		}
		if lastUsed.After(latestUsed) {
			latestUsed = lastUsed
			usedBy = kind + ":" + name
		}

		if latestUsed.IsZero() {
			// Means it's never been used
			fmt.Println("Policy", *policy.PolicyName, "has never been used.")
			result = append(result, Policy{
				PolicyName:     policy.PolicyName,
				PolicyArn:      policy.PolicyArn,
				LastUsed:       time.Time{},
				IsAttachedable: isAttached,
				UsedBy:         "",
				Flag:           "NeverUsed",
				Tags:           policy.Tags,
			})
		} else {
			// Mark as stale if older than 1 year
			flag := ""
			if time.Since(latestUsed) > 365*24*time.Hour {
				flag = "Stale (>1yr)"
			} else if time.Since(latestUsed) > 30*24*time.Hour {
				flag = "Stale (>30d)"
			} else if time.Since(latestUsed) > 7*24*time.Hour {
				flag = "Stale (>7d)"
			} else if time.Since(latestUsed) > 0 {
				flag = "Active (<7d)"
			}
			result = append(result, Policy{
				PolicyName:     policy.PolicyName,
				PolicyArn:      policy.PolicyArn,
				LastUsed:       latestUsed,
				IsAttachedable: isAttached,
				UsedBy:         usedBy,
				Flag:           flag,
				Tags:           policy.Tags,
			})
			fmt.Println("Policy", *policy.PolicyName, "was last used on", latestUsed.Format("2006-01-02"))
		}
	}
	return result, nil
}
