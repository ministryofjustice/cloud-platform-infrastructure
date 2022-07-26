package integration_tests

import (
	"context"
	"strings"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// canIPerformAction is a wrapper for the Terratest kubectl command. It should return a bool dependant on the
// outcome of an `auth can-i` command.
func canIPerformAction(kubectlOptions *k8s.KubectlOptions, verb, resource, user, namespace string) (string, error) {
	return k8s.RunKubectlAndGetOutputE(GinkgoT(), kubectlOptions, "auth", "can-i", verb, resource, "--namespace", namespace, "--as", "test", "--as-group github:"+user, "--as-group system:authenticated")
}

var _ = Describe("Namespaces", func() {
	Context("By impersonating a non-privileged user", func() {
		var (
			verb, resource, impersonateUser string
		)

		options := k8s.NewKubectlOptions("", "", "")
		FIt("shouldn't be able to get resources in system namespaces", func() {
			verb = "get"
			resource = "pods"
			impersonateUser = "notWebops"

			for _, namespace := range []string{"kube-system", "kube-public"} {
				// We deliberately don't handle the error here as it will always fail.
				output, _ := canIPerformAction(options, verb, resource, impersonateUser, namespace)
				// Expect(err).NotTo(HaveOccurred())

				Expect(output).To(ContainSubstring("no"))
			}
		})
	})

	Context("when checking kube-system", func() {
		It("should contain OPA labels", func() {
			// Get the kube-system namespace, it should contain an ignore for OPA.
			// If it doesn't, nothing will deploy there.
			namespace, err := c.Client.Clientset.CoreV1().Namespaces().Get(context.TODO(), "kube-system", metav1.GetOptions{})
			Expect(err).ToNot(HaveOccurred())

			labels := namespace.GetLabels()
			Expect(labels).To(HaveKeyWithValue("openpolicyagent.org/webhook", "ignore"))
		})
	})

	Context("when checking current namespaces", func() {
		GinkgoWriter.Printf("Getting list of namespaces\n")
		namespaces, err := c.Client.Clientset.CoreV1().Namespaces().List(context.TODO(), metav1.ListOptions{})
		Expect(err).To(BeNil())

		It("should contain all expected namespaces", func() {
			// Populate the expected namespaces in the cluster
			c.ExpectedNamespaces()

			// To match the namespace names in the cluster with the expected namespaces in the test, we need to
			// add them to their own slice.
			var namespacesInCluster []string
			for _, namespace := range namespaces.Items {
				namespacesInCluster = append(namespacesInCluster, namespace.GetName())
			}

			GinkgoWriter.Printf("Checking the expected namespaces exist: %s\n", c.Namespaces)
			for _, namespace := range c.Namespaces {
				Expect(namespacesInCluster).To(ContainElement(namespace))
			}
		})

		// Namespaces must have the appropriate annotations for things like
		// monitoring. This test checks all namespaces for annotations. If the
		// annotation list appears empty, it will fail.
		It("must have the appropriate annotations", func() {
			toIgnore := []string{
				"kube-system",
				"kube-public",
				"kube-node-lease",
				"default",
			}

		out:
			for _, namespace := range namespaces.Items {
				// If the namespace is in the ignore list, skip it
				for _, ignore := range toIgnore {
					namespaceName := namespace.Name
					if namespaceName == ignore || strings.Contains(namespaceName, "smoketest") {
						continue out
					}
				}

				// Get the annotations
				annotations := namespace.GetAnnotations()
				Expect(annotations).ShouldNot(BeEmpty())
			}
		})
	})
})
