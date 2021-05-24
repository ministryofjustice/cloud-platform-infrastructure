package integration_tests

// import (
// 	"fmt"

// 	"github.com/gruntwork-io/terratest/modules/k8s"
// 	"github.com/onsi/ginkgo"
// 	. "github.com/onsi/ginkgo"
// )

// var _ = Describe("Daemonset checks", func() {
// 	It("should exist exist the following daemonsets", func() {
// 		if len(c.Namespaces) == 0 {
// 			Skip("None namespaces defined, skipping test")
// 		}

// 		for ns, _ := range c.Namespaces {
// 			options := k8s.NewKubectlOptions("", "", ns)
// 			_, err := k8s.GetNamespaceE(GinkgoT(), options, ns)

// 			if err != nil {
// 				ginkgo.Fail(fmt.Sprintf("Namespace %s DOES NOT exist", ns))
// 			}
// 		}
// 	})
// })
