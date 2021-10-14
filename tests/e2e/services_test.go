package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo"
)

// Services defined in plain text in the cluster manifest.
var _ = Describe("Expected services in the cluster", func() {
	var (
		servicesNotRunning []string
	)

	It("exist", func() {
		services := c.GetExpectedServices()

		if len(services) == 0 {
			Skip("No services defined, skipping test")
		}

		for namespace, svc := range services {
			options := k8s.NewKubectlOptions("", "", namespace)
			for _, v := range svc {
				_, err := k8s.GetServiceE(GinkgoT(), options, v)
				if err != nil {
					servicesNotRunning = append(servicesNotRunning, v)
				}
			}
		}

		if servicesNotRunning != nil {
			Fail(fmt.Sprintf("The following services DO NOT exist: %v", servicesNotRunning))
		}
	})
})
