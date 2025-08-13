package utils

import (
	"bytes"
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// S3Client creates a new S3 client for all S3 operations
func S3Client(ctx context.Context, region string) (*s3.Client, error) {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return nil, err
	}
	return s3.NewFromConfig(cfg), nil
}

// UpdateS3FileDetails updates the contents of a file in S3
func UpdateS3FileDetails(bucket, s3Key string, file []byte, client *s3.Client) error {
	putInput := &s3.PutObjectInput{
		Bucket: &bucket,
		Key:    aws.String(s3Key),
		Body:   bytes.NewReader(file),
	}
	_, err := client.PutObject(context.Background(), putInput)
	if err != nil {
		return fmt.Errorf("failed to put object to S3: %w", err)
	}

	return nil
}
