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
)

var _ = Describe("modsec-ingress-controller", func() {
	var (
		namespaceName, host, url string
		options                  *k8s.KubectlOptions

		goodUrl, badUrl string
		tpl             string
	)

	BeforeEach(func() {
		namespaceName = fmt.Sprintf("%s-modsec-%s", c.Prefix, strings.ToLower(random.UniqueId()))
		host = fmt.Sprintf("%s.apps.%s.%s", namespaceName, c.ClusterName, domain)

		url = fmt.Sprintf("https://%s", host)
		options = k8s.NewKubectlOptions("", "", namespaceName)
		goodUrl = fmt.Sprintf("https://%s", host)
		badUrl = fmt.Sprintf("%s?exec=/bin/bash", url)

		err := k8s.CreateNamespaceE(GinkgoT(), options, namespaceName)
		Expect(err).ToNot(HaveOccurred())
	})

	AfterEach(func() {
		defer k8s.KubectlDeleteFromString(GinkgoT(), options, tpl)
		defer k8s.DeleteNamespace(GinkgoT(), options, namespaceName)
	})

	Context("when ingress resource is deployed using 'modsec01' ingress controller and modsec enabled", func() {
		It("should block the request if the url is malicious", func() {
			setIdentifier := "integration-test-app-ing-" + namespaceName + "-green"

			TemplateVars := map[string]interface{}{
				"ingress_annotations": map[string]string{
					"kubernetes.io/ingress.class":                     "modsec01",
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
					"nginx.ingress.kubernetes.io/enable-modsecurity":  "\"true\"",
					"nginx.ingress.kubernetes.io/modsecurity-snippet": "|\n     SecRuleEngine On",
				},
				"host":      host,
				"namespace": namespaceName,
			}

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment.yaml.tmpl", "helloworld-deployment.yaml.tmpl", TemplateVars)
			if err != nil {
				Fail(err.Error())
			}

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			k8s.WaitUntilIngressAvailable(GinkgoT(), options, "integration-test-app-ing", 6, 20*time.Second)

			By("Checking that the request is blocked")
			Eventually(func() int {
				resp, err := helpers.HttpStatusCode(badUrl)
				Expect(err).ToNot(HaveOccurred())
				return resp
			}, "8m", "30s").Should(Equal(403))

			By("Checking the request is allowed")
			Eventually(func() int {
				resp, err := helpers.HttpStatusCode(goodUrl)
				Expect(err).ToNot(HaveOccurred())
				return resp
			}, "30m", "30s").Should(Equal(200))
		})
	})

	Context("when ingress resource is deployed using 'modsec' ingress controller and modsec enabled", func() {
		It("should block the request if the url is malicious", func() {
			class := "modsec"

			setIdentifier := "integration-test-app-ing-" + namespaceName + "-green"

			TemplateVars := map[string]interface{}{
				"ingress_annotations": map[string]string{
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
					"nginx.ingress.kubernetes.io/enable-modsecurity":  "\"true\"",
					"nginx.ingress.kubernetes.io/modsecurity-snippet": "|\n     SecRuleEngine On",
				},
				"host":      host,
				"class":     class,
				"namespace": namespaceName,
			}

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment-v1.yaml.tmpl", "helloworld-deployment-v1.yaml.tmpl", TemplateVars)
			if err != nil {
				Expect(err).ToNot(HaveOccurred())
			}

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			k8s.WaitUntilIngressAvailable(GinkgoT(), options, "integration-test-app-ing", 8, 20*time.Second)

			By("Checking that the request is blocked")
			Eventually(func() int {
				resp, err := helpers.HttpStatusCode(badUrl)
				Expect(err).ToNot(HaveOccurred())
				return resp
			}, "8m", "30s").Should(Equal(403))

			By("Checking the request is allowed")
			Eventually(func() int {
				resp, err := helpers.HttpStatusCode(goodUrl)
				Expect(err).ToNot(HaveOccurred())
				return resp
			}, "8m", "30s").Should(Equal(200))
		})
	})
})
