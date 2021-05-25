package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/onsi/ginkgo"
	. "github.com/onsi/ginkgo"
)

var _ = Describe("Namespace checks", func() {
	var (
		notFoundNamespaces []string
	)

	It("should exist exist the following namespaces", func() {
		if len(c.Namespaces) == 0 {
			Skip("None namespaces defined, skipping test")
		}

		for ns, _ := range c.Namespaces {
			options := k8s.NewKubectlOptions("", "", ns)
			_, err := k8s.GetNamespaceE(GinkgoT(), options, ns)

			if err != nil {
				notFoundNamespaces = append(notFoundNamespaces, ns)
			}
		}

		if notFoundNamespaces != nil {
			ginkgo.Fail(fmt.Sprintf("The following namespaces DOES NOT exist: %v", notFoundNamespaces))
		}
	})
})
