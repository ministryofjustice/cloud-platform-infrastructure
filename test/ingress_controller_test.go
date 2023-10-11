package integration_tests

import (
	"fmt"
	"strings"
	"time"

	. "github.com/onsi/ginkgo/v2"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

var _ = Describe("ingress-controllers", func() {
	var (
		namespaceName, host, url string
		options                  *k8s.KubectlOptions
	)

	BeforeEach(func() {
		namespaceName = fmt.Sprintf("%s-ing-%s", c.Prefix, strings.ToLower(random.UniqueId()))
		host = fmt.Sprintf("%s.apps.%s.%s", namespaceName, c.ClusterName, domain)
		options = k8s.NewKubectlOptions("", "", namespaceName)
		url = fmt.Sprintf("https://%s", host)

		nsObject := metav1.ObjectMeta{
			Name: namespaceName,
			Labels: map[string]string{
				"pod-security.kubernetes.io/audit": "restricted",
			},
		}

		err := k8s.CreateNamespaceWithMetadataE(GinkgoT(), options, nsObject)
		Expect(err).ToNot(HaveOccurred())
	})

	AfterEach(func() {
		err := k8s.DeleteNamespaceE(GinkgoT(), options, namespaceName)
		Expect(err).ToNot(HaveOccurred())
	})

	Context("when an ingress resource is deployed using 'default' ingress controller", func() {
		It("should expose the service to the internet", func() {
			setIdentifier := "integration-test-app-ing-" + namespaceName + "-green"
			class := "default"

			TemplateVars := map[string]interface{}{
				"ingress_annotations": map[string]string{
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
				},
				"host":      host,
				"class":     class,
				"namespace": namespaceName,
			}

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment-v1.yaml.tmpl", "helloworld-deployment-v1.yaml.tmpl", TemplateVars)
			if err != nil {
				Fail("Failed to create helloworld deployment: " + err.Error())
			}

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).To(BeNil())

			k8s.WaitUntilIngressAvailable(GinkgoT(), options, "integration-test-app-ing", 8, 20*time.Second)

			GinkgoWriter.Printf("Checking that the ingress is available at %s\n", url)
			Eventually(func() int {
				s, err := helpers.HttpStatusCode(url)
				Expect(err).To(BeNil())

				return s
			}, "8m", "30s").Should(Equal(200))
		})
	})
})
