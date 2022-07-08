package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Daemonsets", func() {
	var notFoundDaemonSets []string

	Context("expected daemonsets", func() {
		It("should exist the in the cluster", func() {
			c.ExpectedDaemonSets()

			if len(c.DaemonSets) == 0 {
				Skip("No daemonsets defined, skipping test")
			}

			options := k8s.NewKubectlOptions("", "", "")

			list, err := k8s.ListDaemonSetsE(GinkgoT(), options, metav1.ListOptions{})
			if err != nil {
				Fail(fmt.Sprintf("Failed to list daemonsets: %s", err))
			}

			for _, daemonSet := range c.DaemonSets {
				var found bool
				for _, d := range list {
					if d.Name == daemonSet {
						found = true
						continue
					}

				}
				if !found {
					notFoundDaemonSets = append(notFoundDaemonSets, daemonSet)
				}
			}

			Expect(notFoundDaemonSets).To(BeEmpty())
		})
	})
})
