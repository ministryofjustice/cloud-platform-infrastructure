package aws

import (
	"bytes"
	"context"
	"io"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/s3/manager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// DownloadCSVFromS3ToReader downloads an S3 object and returns an io.Reader for its contents.
func DownloadCSVFromS3ToReader(bucket, key string) (io.Reader, error) {
	ctx := context.Background()
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("eu-west-2"))
	if err != nil {
		return nil, err
	}
	client := s3.NewFromConfig(cfg)
	buf := manager.NewWriteAtBuffer([]byte{})
	downloader := manager.NewDownloader(client)
	_, err = downloader.Download(ctx, buf, &s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return nil, err
	}
	return bytes.NewReader(buf.Bytes()), nil
}
