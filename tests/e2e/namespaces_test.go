package integration_tests

import (
	"fmt"
	"regexp"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Namespace checks refer to checks that involve namespace
// specifics in a cluster.
var _ = Describe("Namespace checks", func() {
	var (
		notFoundNamespaces []string
	)

	// Namespaces listed in the config file should exist.
	It("should contain namespaces outlined in the config file", func() {
		if len(c.Namespaces) == 0 {
			Skip("No namespaces have been found. Skipping.")
		}

		// Loop over namespaces defined in the config file and add them
		// to a collection if not found.
		for ns := range c.Namespaces {
			options := k8s.NewKubectlOptions("", "", ns)
			_, err := k8s.GetNamespaceE(GinkgoT(), options, ns)

			if err != nil {
				notFoundNamespaces = append(notFoundNamespaces, ns)
			}
		}

		// If the notFoundNamespaces collection contains and entry the test will fail.
		if notFoundNamespaces != nil {
			Fail(fmt.Sprintf("The following namespaces DO NOT exist: %v", notFoundNamespaces))
		}
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
