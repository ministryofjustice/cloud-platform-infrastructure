package integration_tests

import (
	"fmt"
	"math/rand"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("cert-manager", func() {
	var (
		namespace    = fmt.Sprintf("cert-manager-test-%v", rand.Int())
		ingressClass = "nginx"
		ingressName  = "integration-test"
		options      = k8s.NewKubectlOptions("", "", namespace)
	)

	BeforeEach(func() {
		// create namespace
		k8s.CreateNamespace(GinkgoT(), options, namespace)
		// create ingress resource
		// create certificate
	})

	AfterEach(func() {
		// destroy ingress resource
		// destroy namespace
	})

	Context("when a certificate resource is created", func() {
		// validate_certificate
		// gomega validation
	})
})
