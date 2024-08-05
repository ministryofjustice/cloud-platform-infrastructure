package integration_tests

import (
	"context"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	testHelpers "github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
)

var _ = Describe("Monitoring", func() {
	namespace := "monitoring"
	options := k8s.NewKubectlOptions("", "", namespace)
	client, err := testHelpers.GetPrometheusClientSetE(GinkgoT(), options)
	if err != nil {
		Fail(err.Error())
	}
	c.ExpectedPromRules()

	// For our manager cluster we expect additional rule(s)
	if c.ClusterName == "manager" {
		c.ExpectedManagerPromRules()
	}

	// Get all custom resource definitions
	crds, err := client.PrometheusRules(namespace).List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		Fail(err.Error())
	}

	// Spit list of prometheus rules into a slice containing the name only
	var ruleNames []string
	for _, crd := range crds.Items {
		ruleNames = append(ruleNames, crd.GetName())
	}

	It("should have the expected custom resources", func() {
		Expect(ruleNames).To(ConsistOf(c.PrometheusRules))
	})
})
