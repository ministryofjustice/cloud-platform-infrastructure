package integration_tests

import (
	"fmt"

	. "github.com/onsi/ginkgo"
)

var _ = Describe("ServiceMonitors checks", func() {
	var notFoundServiceMonitors []string

	It("should exist the following servicemonitors", func() {
		c.ExpectedServiceMonitors()

		if len(c.ServiceMonitors) == 0 {
			Skip("No servicemonitors defined, skipping test")
		}

		// for ns, sm := range c.ServiceMonitors {
		// 	options := k8s.NewKubectlOptions("", "", ns)

		// 	for _, v := range sm {
		// 		_, err := testHelpers.GetServiceMonitorSetE(GinkgoT(), options, v)
		// 		if err != nil {
		// 			notFoundServiceMonitors = append(notFoundServiceMonitors, v)
		// 	}
		// }
		// }

		if notFoundServiceMonitors != nil {
			Fail(fmt.Sprintf("The following servicemonitors DO NOT exist: %v", notFoundServiceMonitors))
		}
	})
})
