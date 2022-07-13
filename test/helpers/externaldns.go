package helpers

import (
	"fmt"
	"net"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/route53"
)

// RecordSets uses the AWS API to return domain entry existence in Route53
// using the hostzone ID specified in the configuration
func RecordSets(d, hostedZone string) (bool, error) {
	svc := route53.New(session.New())

	params := &route53.ListResourceRecordSetsInput{
		HostedZoneId: aws.String(hostedZone),
	}

	sets, err := svc.ListResourceRecordSets(params)
	if err != nil {
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

// DNSLookUp returns error if there is not DNS entry for an endpoint, used
// with retry library from terratest
func DNSLookUp(h string) (string, error) {
	if _, err := net.LookupIP(h); err != nil {
		return "", fmt.Errorf("DNS propagation hasn't happened'%w'", err)
	}

	return "", nil
}
