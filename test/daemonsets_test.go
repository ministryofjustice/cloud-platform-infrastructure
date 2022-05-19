package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"

	. "github.com/onsi/ginkgo"
)

var _ = Describe("Daemonsets checks", func() {
	var notFoundDaemonSets []string

	It("should exist the following daemonsets", func() {
		daemonSets := c.GetExpectedDaemonSets()

		if len(daemonSets) == 0 {
			Skip("No daemonsets defined, skipping test")
		}

		for ns, ds := range daemonSets {
			options := k8s.NewKubectlOptions("", "", ns)
			for _, v := range ds {
				_, err := k8s.GetDaemonSetE(GinkgoT(), options, v)
				if err != nil {
					notFoundDaemonSets = append(notFoundDaemonSets, v)
				}
			}
		}

		if notFoundDaemonSets != nil {
			Fail(fmt.Sprintf("The following daemonsets DO NOT exist: %v", notFoundDaemonSets))
		}
	})
})
