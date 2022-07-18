package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"
	testHelpers "github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("ServiceMonitors", func() {
	It("should exist in the cluster", func() {
		c.ExpectedServiceMonitors()

		var nonExistingServiceMonitors []string

		By("Checking that the ServiceMonitors are running")
		for namespace, serviceMonitors := range c.ServiceMonitors {
			for _, serviceMonitor := range serviceMonitors {
				_, err := testHelpers.GetServiceMonitorSetE(GinkgoT(), k8s.NewKubectlOptions("", "", namespace), serviceMonitor)
				if err != nil {
					nonExistingServiceMonitors = append(nonExistingServiceMonitors, fmt.Sprintf("%s/%s", namespace, serviceMonitor))
				}
			}
		}

		Expect(nonExistingServiceMonitors).To(BeEmpty())
	})
})
