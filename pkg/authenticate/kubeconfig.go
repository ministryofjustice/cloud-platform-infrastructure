package authenticate

import (
	"errors"
	"io/ioutil"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func FromS3Bucket(bucket, configFile, clusterCtx, region string) (clientset *kubernetes.Clientset, err error) {
	buff := &aws.WriteAtBuffer{}
	downloader := s3manager.NewDownloader(session.New(&aws.Config{
		Region: aws.String(region),
	}))

	numBytes, err := downloader.Download(buff, &s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(configFile),
	})

	if err != nil {
		return nil, err
	}
	if numBytes < 1 {
		return nil, errors.New("The file downloaded is incorrect.")
	}

	data := buff.Bytes()
	err = ioutil.WriteFile(configFile, data, 0644)
	if err != nil {
		return nil, err
	}

	defer os.Remove(configFile)

	client, err := clientcmd.NewNonInteractiveDeferredLoadingClientConfig(
		&clientcmd.ClientConfigLoadingRules{ExplicitPath: configFile},
		&clientcmd.ConfigOverrides{
			CurrentContext: clusterCtx,
		}).ClientConfig()
	if err != nil {
		return nil, err
	}

	clientset, _ = kubernetes.NewForConfig(client)
	if err != nil {
		return nil, err
	}

	return
}
