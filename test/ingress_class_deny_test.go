package integration_tests

import (
	"fmt"
	"strings"

	. "github.com/onsi/ginkgo/v2"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

var _ = Describe("ingress-controllers", Serial, func() {
	var (
		namespaceName, host string
		options             *k8s.KubectlOptions
	)

	BeforeEach(func() {
		namespaceName = fmt.Sprintf("%s-ing-%s", c.Prefix, strings.ToLower(random.UniqueId()))
		host = fmt.Sprintf("%s.apps.%s.%s", namespaceName, c.ClusterName, domain)
		options = k8s.NewKubectlOptions("", "", namespaceName)

		nsObject := metav1.ObjectMeta{
			Name: namespaceName,
			Labels: map[string]string{
				"pod-security.kubernetes.io/enforce": "restricted",
			},
		}

		err := k8s.CreateNamespaceWithMetadataE(GinkgoT(), options, nsObject)
		Expect(err).ToNot(HaveOccurred())
	})

	AfterEach(func() {
		err := k8s.DeleteNamespaceE(GinkgoT(), options, namespaceName)
		Expect(err).ToNot(HaveOccurred())
	})

	Context("when an ingress resource is deployed using invalid ingress class", func() {
		It("should fail with gatekeeper deny msg", func() {
			setIdentifier := "integration-test-app-ing-" + namespaceName + "-green"
			class := "bad-ingress-class"

			TemplateVars := map[string]interface{}{
				"ingress_annotations": map[string]string{
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
				},
				"host":      host,
				"class":     class,
				"namespace": namespaceName,
			}

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment-v1-default-cert.yaml.tmpl", "helloworld-deployment-v1-default-cert.yaml.tmpl", TemplateVars)
			if err != nil {
				Fail("Failed to create helloworld deployment: " + err.Error())
			}

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(BeNil())
			Expect(err.Error()).To(ContainSubstring("denied the request: [k8singressclassname]"))
		})
	})
})
