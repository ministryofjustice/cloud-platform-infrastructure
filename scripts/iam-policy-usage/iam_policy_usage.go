package main

import (
	"context"
	"encoding/csv"
	"fmt"
	"os"
	"strings"
	"time"

	// AWS SDK packages
	"github.com/aws/aws-sdk-go-v2/aws"         // Used for getting core AWS service API calls
	"github.com/aws/aws-sdk-go-v2/config"      // Loads AWS creds
	"github.com/aws/aws-sdk-go-v2/service/iam" // IAM client
	"github.com/aws/aws-sdk-go-v2/service/sts" // Gets AWS account ID
)

func main() {
	ctx := context.Background()

	// Load AWS creds
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		fmt.Println("Could not load AWS config:", err)
		return
	}

	// Create IAM client
	iamClient := iam.NewFromConfig(cfg)

	// Get AWS account ID
	accountID, err := getAccountID(ctx, cfg)
	if err != nil {
		fmt.Println("Error getting account ID:", err)
		return
	}

	// Create a CSV file to save the results
	file, err := os.Create("policy_usage.csv")
	if err != nil {
		fmt.Println("Error creating file:", err)
		return
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Write header row to the CSV file
	writer.Write([]string{"PolicyName", "PolicyArn", "AttachmentStatus", "LastUsed", "UsedByEntity", "Flag"})

	// Get all CMK IAM policies
	paginator := iam.NewListPoliciesPaginator(iamClient, &iam.ListPoliciesInput{
		Scope: "Local", // Local = CMK
	})

	// Loop through all pages of results
	for paginator.HasMorePages() {
		page, err := paginator.NextPage(ctx)
		if err != nil {
			fmt.Println("Could not get list of policies:", err)
			return
		}

		// Check each policy
		for _, policy := range page.Policies {
			policyName := *policy.PolicyName
			policyArn := *policy.Arn

			//Which users/roles/groups are using this policy
			entities, err := iamClient.ListEntitiesForPolicy(ctx, &iam.ListEntitiesForPolicyInput{
				PolicyArn: &policyArn,
			})
			if err != nil {
				fmt.Println("Could not get entities for policy", policyName)
				continue
			}

			// Check if the policy is attached to anything
			isAttached := len(entities.PolicyRoles) > 0 || len(entities.PolicyUsers) > 0 || len(entities.PolicyGroups) > 0

			// If not attached, mark as UNUSED
			if !isAttached {
				fmt.Println("Policy", policyName, "is not attached to anything.")
				writer.Write([]string{policyName, policyArn, "NotAttached", "NeverUsed", "", "Unused"})
				continue
			}

			// If attached, check when it was last used
			latestUsed := time.Time{}
			usedBy := ""

			// Check usage by roles
			for _, role := range entities.PolicyRoles {
				lastUsed, err := getLastUsed(ctx, iamClient, accountID, *role.RoleName, "role")
				if err != nil && strings.Contains(err.Error(), "ExpiredToken") {
					writer.Write([]string{policyName, policyArn, "Attached", "Unknown", "", "TokenExpired"})
					fmt.Println("Token expired while checking", policyName)
					continue
				}
				if lastUsed.After(latestUsed) {
					latestUsed = lastUsed
					usedBy = "Role:" + *role.RoleName
				}
			}

			// Check usage by users
			for _, user := range entities.PolicyUsers {
				lastUsed, err := getLastUsed(ctx, iamClient, accountID, *user.UserName, "user")
				if err != nil && strings.Contains(err.Error(), "ExpiredToken") {
					writer.Write([]string{policyName, policyArn, "Attached", "Unknown", "", "TokenExpired"})
					fmt.Println("Token expired while checking", policyName)
					continue
				}
				if lastUsed.After(latestUsed) {
					latestUsed = lastUsed
					usedBy = "User:" + *user.UserName
				}
			}

			// Write the usage data to the CSV file
			if latestUsed.IsZero() {
				// Means it's never been used
				fmt.Println("Policy", policyName, "has never been used.")
				writer.Write([]string{policyName, policyArn, "Attached", "NeverUsed", "", "Unused"})
			} else {
				// Mark as stale if older than 1 year
				flag := ""
				if time.Since(latestUsed) > 365*24*time.Hour {
					flag = "Stale (>1yr)"
				}
				writer.Write([]string{
					policyName,
					policyArn,
					"Attached",
					latestUsed.Format("2006-01-02"),
					usedBy,
					flag,
				})
				fmt.Println("Policy", policyName, "was last used on", latestUsed.Format("2006-01-02"))
			}
		}
	}

	fmt.Println("\nResults saved in policy_usage.csv")
}

// Get the AWS account ID
func getAccountID(ctx context.Context, cfg aws.Config) (string, error) {
	stsClient := sts.NewFromConfig(cfg)

	output, err := stsClient.GetCallerIdentity(ctx, &sts.GetCallerIdentityInput{})
	if err != nil {
		return "", err
	}

	return *output.Account, nil
}

// Check when a role or user was last used
func getLastUsed(ctx context.Context, client *iam.Client, accountID string, name string, kind string) (time.Time, error) {
	var arn string

	if kind == "user" {
		arn = fmt.Sprintf("arn:aws:iam::%s:user/%s", accountID, name)
	} else if kind == "role" {
		arn = fmt.Sprintf("arn:aws:iam::%s:role/%s", accountID, name)
	} else {
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
