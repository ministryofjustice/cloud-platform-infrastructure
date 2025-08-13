package main

import (
	"bytes"
	"context"
	"encoding/csv"
	"fmt"
	"unused-policies/utils"

	// AWS SDK packages
	// Used for getting core AWS service API calls

	"github.com/aws/aws-sdk-go-v2/config" // Loads AWS creds
	// IAM client
	// Gets AWS account ID
)

func derefString(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func main() {
	ctx := context.Background()

	// Load AWS configuration
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		fmt.Println("Could not load AWS config:", err)
		return
	}

	// Create IAM client
	iamClient := utils.IAMClient(cfg)

	// List policies
	policies, err := utils.ListAllPolicies(iamClient, ctx)
	if err != nil {
		fmt.Println("Error listing policies:", err)
		return
	}

	// Get account ID
	accountID, err := utils.GetAccountID(ctx, cfg)
	if err != nil {
		fmt.Println("Error getting account ID:", err)
		return
	}

	// Get policy last used information
	results, err := utils.GetPolicyLastUsed(iamClient, ctx, policies, accountID)
	if err != nil {
		fmt.Println("Error getting policy last used:", err)
		return
	}

	// write to csv file
	// file, err := os.Create("et_policy_usage.csv")
	// if err != nil {
	// 	fmt.Println("Error creating CSV file:", err)
	// 	return
	// }
	// defer file.Close()

	// byte slice to hold CSV data
	var buf bytes.Buffer
	writer := csv.NewWriter(&buf)

	// Write CSV header
	writer.Write([]string{"PolicyName", "PolicyArn", "LastUsed", "IsAttachedable", "UsedByEntity", "Flag", "Tags"})

	// Write policy usage data
	for _, policy := range results {
		// Convert tags to a string
		var tagsStr string
		for i, tag := range policy.Tags {
			if i > 0 {
				tagsStr += ";"
			}
			tagsStr += fmt.Sprintf("%s=%s", derefString(tag.Key), derefString(tag.Value))
		}
		policyName := derefString(policy.PolicyName)
		policyArn := derefString(policy.PolicyArn)
		lastUsed := ""
		if !policy.LastUsed.IsZero() {
			lastUsed = policy.LastUsed.Format("2006-01-02")
		}
		writer.Write([]string{
			policyName,
			policyArn,
			lastUsed,
			policy.IsAttachedable,
			policy.UsedBy,
			policy.Flag,
			tagsStr,
		})
	}

	writer.Flush()

	s3Client, err := utils.S3Client(ctx, "eu-west-2") // Replace with your desired region
	if err != nil {
		fmt.Println("Error creating S3 client:", err)
		return
	}

	err = utils.UpdateS3FileDetails("raz-webops", "policy_usage.csv", buf.Bytes(), s3Client)
	if err != nil {
		fmt.Println("Error updating S3 file details:", err)
		return
	}
}
