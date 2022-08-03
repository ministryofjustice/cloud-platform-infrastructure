package integration_tests

import (
	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Custom resource definitions", func() {
	options := k8s.NewKubectlOptions("", "", "")

	// Get all expected CRDs from config
	c.ExpectedCrds()

	// Get all custom resource definitions
	crds, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "crd")
	if err != nil {
		Fail(err.Error())
	}

	It("should return all expected CRDs", func() {
		for _, expectedCrd := range c.CustomResourceDefinitions {
			Expect(crds).To(ContainSubstring(expectedCrd))
		}
	})
})
