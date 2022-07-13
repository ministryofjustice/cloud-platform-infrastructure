package integration_tests

import (
	"fmt"
	"regexp"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

var _ = Describe("Namespaces", func() {
	Context("expected namespaces", func() {
		It("should exist in the cluster", func() {
			// Populate the expected namespaces in the cluster
			c.ExpectedNamespaces()
			var notFound []string

			for _, namespace := range c.Namespaces {
				options := k8s.NewKubectlOptions("", "", namespace)
				_, err := k8s.GetNamespaceE(GinkgoT(), options, namespace)
				if err != nil {
					notFound = append(notFound, namespace)
				}
			}
			Expect(notFound).Error().Should(BeEmpty())
		})

		// Namespaces must have the appropriate annotations for things like
		// monitoring. This test checks all namespaces for annotations. If the
		// annotation list appears empty, it will fail.
		It("must have the appropriate annotations", func() {
			options := k8s.NewKubectlOptions("", "", "")
			listOptions := metav1.ListOptions{}

			// Grab all pods in the cluster to query the namespace name.
			allPods := k8s.ListPods(GinkgoT(), options, listOptions)

			// Becuase of the lack of a 'get all ns' in terratest we
			// need to loop over every pod, grab the namepspace name
			// and add it to a map. A map was chosen so we can perform
			// a quick lookup of duplicates (because of the lack of
			// slice.contains in go).
			m := make(map[string]string)
			for _, ns := range allPods {
				// exclude ephemeral namespaces created by the framework itself
				r := regexp.MustCompile("^smoketest-.*")
				if r.MatchString(ns.Namespace) == true {
					continue
				}

				_, ok := m[ns.Namespace]
				if !ok {
					m[ns.Namespace] = ""
				}
			}

			// Loop over each key in the map and add namespace names
			// to a collection.
			var unannotatedNs []string
			for k := range m {
				ns, _ := k8s.GetNamespaceE(GinkgoT(), options, k)
				if len(ns.Annotations) < 1 {
					unannotatedNs = append(unannotatedNs, ns.Name)
				}
			}

			// If the unannotatedNs collection has entries the test will fail.
			if unannotatedNs != nil {
				Fail(fmt.Sprintf("The following namespaces DO NOT have annotations: %v", unannotatedNs))
			}
		})
	})
})
