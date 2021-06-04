package helpers

import (
	"fmt"
	"strings"

	"github.com/davecgh/go-spew/spew"
	"github.com/ministryofjustice/tiny-k8s-tester/pkg/config"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/route53"
)

// RecordSets uses the AWS API to return domain entry existence in Route53
// using the hostzone ID specified in the configuration
func RecordSets(d string, c *config.ExternalDNS) (bool, error) {
	svc := route53.New(session.New())

	params := &route53.ListResourceRecordSetsInput{
		HostedZoneId: aws.String(c.HostedZoneId),
	}

	sets, err := svc.ListResourceRecordSets(params)
	if err != nil {
		return false, err
	}

	for _, v := range sets.ResourceRecordSets {
		record := strings.TrimRight(*v.Name, ".")
		spew.Dump(record)
		if record == d {
			fmt.Println("FOUND! Returning now")
			return true, nil
		}
	}

	return false, nil
}
