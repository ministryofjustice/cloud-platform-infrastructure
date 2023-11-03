package integration_tests

import (
	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("GIVEN a gatekeeper installation", func() {
	options := k8s.NewKubectlOptions("", "", "gatekeeper-system")

	expectedMutations := []string{
		"default-fs-group",
		"default-seccomp-profile",
		"default-supplemental-groups",
		"deny-privilege-escalation",
		"deny-privilege-escalation-eph",
		"deny-privilege-escalation-init",
		"drop-all-cap",
		"drop-all-cap-eph",
		"drop-all-cap-init",
		"run-as-non-root",
		"run-as-non-root-eph",
		"run-as-non-root-init",
	}

	expectedMetadataMutations := []string{
		"annotate-seccomp-pod-runtime",
	}

	It("THEN return all expected mutations", func() {
		actual, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "assign.mutations.gatekeeper.sh")
		if err != nil {
			Fail(err.Error())
		}

		for _, expected := range expectedMutations {
			Expect(actual).To(ContainSubstring(expected))
		}
	})

	It("THEN return all expected metadata mutations", func() {
		actual, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "assignmetadata.mutations.gatekeeper.sh")
		if err != nil {
			Fail(err.Error())
		}

		for _, expected := range expectedMetadataMutations {
			Expect(actual).To(ContainSubstring(expected))
		}
	})
})
