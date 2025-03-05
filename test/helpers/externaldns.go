package helpers

import (
	"fmt"
	"net"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/route53"
)

// Retry and wait time for Route53 API calls - throttling issue exponential backoff/retry strategy
const (
	maxRetries    = 5
	startWaitTime = 1 * time.Second
)

// RecordSets uses the AWS API to return domain entry existence in Route53
// using the hostzone ID specified in the configuration
func RecordSets(d, hostedZone, recordType string) (bool, error) {
	mySession := session.Must(session.NewSession())
	svc := route53.New(mySession)

	params := &route53.ListResourceRecordSetsInput{
		MaxItems:        aws.String("200"),
		HostedZoneId:    aws.String(hostedZone),
		StartRecordType: aws.String(recordType),
		StartRecordName: aws.String(d),
	}

	wait := startWaitTime

	for i := 0; i < maxRetries; i++ {
		sets, err := svc.ListResourceRecordSets(params)
		if err != nil {
			awsErr, ok := err.(awserr.Error)
			if ok && awsErr.Code() == "Throttling" {
				time.Sleep(wait)
				wait *= 2 // exponential backoff
				continue
			}
			return false, err
		}

		for _, v := range sets.ResourceRecordSets {
			record := strings.TrimRight(*v.Name, ".")

			if record == d {
				return true, nil
			}
		}

		return false, nil
	}
	return false, fmt.Errorf("max retries reached")
}

// DNSLookUp returns error if there is not DNS entry for an endpoint, used
// with retry library from terratest
func DNSLookUp(h string) (string, error) {
	if _, err := net.LookupIP(h); err != nil {
		return "", fmt.Errorf("DNS propagation hasn't happened'%w'", err)
	}

	return "", nil
}
