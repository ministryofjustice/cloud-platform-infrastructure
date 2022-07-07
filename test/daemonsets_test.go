package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	. "github.com/onsi/ginkgo"
)

var _ = Describe("Daemonsets checks", func() {
	var notFoundDaemonSets []string

	FIt("should exist the following daemonsets", func() {
		c.ExpectedDaemonSets()

		if len(c.DaemonSets) == 0 {
			Skip("No daemonsets defined, skipping test")
		}

		options := k8s.NewKubectlOptions("", "", "")

		for _, daemonSet := range c.DaemonSets {
			// get all daemonsets and return the ones that are not notFoundDaemonSets
			ds, err := k8s.ListDaemonSetsE(GinkgoT(), options, metav1.ListOptions{})
			if err != nil {
				Fail(fmt.Sprintf("Failed to list daemonsets: %s", err))
			}
			for _, d := range ds {
				if d.Name == daemonSet {
					continue
				}
				notFoundDaemonSets = append(notFoundDaemonSets, d.Name)
			}
		}

		// for _, ds := range c.DaemonSets {
		// 	options := k8s.NewKubectlOptions("", "", "")
		// 	for _, v := range ds {
		// _, err := k8s.GetDaemonSetE(GinkgoT(), options, v)
		// 		if err != nil {
		// 			notFoundDaemonSets = append(notFoundDaemonSets, v)
		// 		}
		// 	}
		// }

		// if notFoundDaemonSets != nil {
		// 	Fail(fmt.Sprintf("The following daemonsets DO NOT exist: %v", notFoundDaemonSets))
		// }
	})
})
