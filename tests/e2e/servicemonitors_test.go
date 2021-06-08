package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"
	cpk8s "github.com/ministryofjustice/tiny-k8s-tester/pkg/tests"
	"github.com/onsi/ginkgo"
	. "github.com/onsi/ginkgo"
)

var _ = Describe("ServiceMonitors checks", func() {
	var (
		notFoundServiceMonitors []string
	)

	It("should exist the following servicemonitors", func() {
		serviceMonitors := c.GetServiceMonitors()

		if len(serviceMonitors) == 0 {
			Skip("No servicemonitors defined, skipping test")
		}

		for ns, sm := range serviceMonitors {
			options := k8s.NewKubectlOptions("", "", ns)

			for _, v := range sm {
				_, err := cpk8s.GetServiceMonitorSetE(GinkgoT(), options, v)
				if err != nil {
					notFoundServiceMonitors = append(notFoundServiceMonitors, v)
				}
			}
		}

		if notFoundServiceMonitors != nil {
			ginkgo.Fail(fmt.Sprintf("The following servicemonitors DO NOT exist: %v", notFoundServiceMonitors))
		}
	})
})
