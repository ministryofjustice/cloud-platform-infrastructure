package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Daemonsets", func() {
	Context("expected daemonsets", func() {
		It("should exist the in the cluster", func() {
			// Populate the daemonsets expected in the cluster
			c.ExpectedDaemonSets()

			// Create options to communicate with terratest.
			// This will query all namespaces in the cluster.
			options := k8s.NewKubectlOptions("", "", "")

			// Get list of all daemonsets objects in the cluster
			list, err := k8s.ListDaemonSetsE(GinkgoT(), options, metav1.ListOptions{})
			if err != nil {
				Fail(fmt.Sprintf("Failed to list daemonsets: %s", err))
			}

			// Loop through the list of objects and put the names in a slice
			var actualDaemonSets []string
			for _, clusterDaemonset := range list {
				actualDaemonSets = append(actualDaemonSets, clusterDaemonset.Name)
			}

			// Compare expected daemonsets to actual daemonsets
			for _, expectedDaemonSet := range c.Daemonsets {
				Expect(actualDaemonSets).To(ContainElement(expectedDaemonSet))
			}

		})
	})
})
