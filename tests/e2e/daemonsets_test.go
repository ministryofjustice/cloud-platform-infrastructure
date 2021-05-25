package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"

	"github.com/onsi/ginkgo"
	. "github.com/onsi/ginkgo"
)

var _ = Describe("Daemonsets checks", func() {
	var (
		notFoundDaemonSets []string
	)

	It("should exist exist the following daemonsets", func() {
		if len(c.Namespaces) == 0 {
			Skip("None daemonsets defined, skipping test")
		}

		for ns, ds := range c.GetDaemonSets() {
			options := k8s.NewKubectlOptions("", "", ns)
			for _, v := range ds {
				_, err := k8s.GetDaemonSetE(GinkgoT(), options, v)

				if err != nil {
					notFoundDaemonSets = append(notFoundDaemonSets, v)
				}
			}
		}

		if notFoundDaemonSets != nil {
			ginkgo.Fail(fmt.Sprintf("The following daemonsets DOES NOT exist: %v", notFoundDaemonSets))
		}
	})
})
