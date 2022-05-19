package integration_tests

import (
	"fmt"
	"html/template"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/config"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("external-DNS checks", func() {
	var (
		namespaceName = c.ExternalDNS.GetNamespaceName()
		options       = k8s.NewKubectlOptions("", "", namespaceName)
		domain        = fmt.Sprintf("%s.%s", namespaceName, c.ExternalDNS.Domain)
		tpl           string
	)

	BeforeEach(func() {
		if (config.ExternalDNS{}) == c.ExternalDNS {
			Skip("Nginx Ingress Controller component not defined, skipping test")
		}

		k8s.CreateNamespace(GinkgoT(), options, namespaceName)
	})

	AfterEach(func() {
		defer k8s.KubectlDeleteFromString(GinkgoT(), options, tpl)
		defer k8s.DeleteNamespace(GinkgoT(), options, namespaceName)
	})

	Context("when ingress resource is created", func() {
		It("should work create the A record", func() {
			By("Deploying ingress resource")

			tpl, err := helpers.TemplateFile("./fixtures/external-dns-ingress.yaml.tmpl", "external-dns-ingress.yaml.tmpl", template.FuncMap{
				"domain":    domain,
				"namespace": namespaceName,
			})
			Expect(err).NotTo(HaveOccurred())

			k8s.KubectlApplyFromString(GinkgoT(), options, tpl)
			k8s.WaitUntilIngressAvailableV1Beta1(GinkgoT(), options, "e2e-tests-externaldns", 60, 5*time.Second)

			By("having an ingress resource deployed we should expect DNS entry for it")

			var existArecord bool

			retry.DoWithRetry(GinkgoT(), fmt.Sprintf("Waiting for sucessfull DNS entry in Route53 (returning: %t)", existArecord), 8, 10*time.Second, func() (string, error) {
				a, err := helpers.RecordSets(domain, &c.ExternalDNS)
				if err != nil {
					return "", err
				}

				if a == false {
					return "", fmt.Errorf("Expected A record in Route53 but the AWS query returns '%t'", a)
				}

				existArecord = a

				return "", nil
			})

			Expect(err).NotTo(HaveOccurred())
			Ω(existArecord).Should(BeTrue())
		})
	})
})
