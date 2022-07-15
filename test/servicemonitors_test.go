package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"
	testHelpers "github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("ServiceMonitors", func() {
	Context("when checking if the expected service monitors exist", func() {
		It("should return true", func() {
			c.ExpectedServiceMonitors()

			var notFound []string

			if len(c.ServiceMonitors) == 0 {
				Skip("No servicemonitors defined, skipping test")
			}

			for namespace, serviceMonitors := range c.ServiceMonitors {
				for _, serviceMonitor := range serviceMonitors {
					_, err := testHelpers.GetPrometheusClientSetE(GinkgoT(), k8s.NewKubectlOptions("", "", namespace))
					if err != nil {
						notFound = append(notFound, fmt.Sprintf("%s/%s", namespace, serviceMonitor))
					}
				}
			}
			Expect(notFound).To(BeEmpty())
		})
	})
})
