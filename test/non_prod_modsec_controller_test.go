package integration_tests

import (
	"fmt"
	"os"
	"strings"
	"time"

	. "github.com/onsi/ginkgo/v2"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	. "github.com/onsi/gomega"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
)

var _ = Describe("modsec-non-prod-ingress-controller", Serial, func() {
	var (
		namespaceName, host, url string
		options                  *k8s.KubectlOptions

		goodUrl, badUrl string
		tpl             string
	)

	BeforeEach(func() {
		if !(c.ClusterName == "live") {
			Skip(fmt.Sprintf("modsec-non-prod ingress class is not deployed on cluster: %s", c.ClusterName))
		}

		namespaceName = fmt.Sprintf("%s-modsec-%s", c.Prefix, strings.ToLower(random.UniqueId()))
		host = fmt.Sprintf("%s.apps.%s.%s", namespaceName, c.ClusterName, domain)

		url = fmt.Sprintf("https://%s", host)
		options = k8s.NewKubectlOptions("", "", namespaceName)
		goodUrl = fmt.Sprintf("https://%s", host)
		badUrl = fmt.Sprintf("%s?exec=/bin/bash", url)

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
		defer k8s.KubectlDeleteFromString(GinkgoT(), options, tpl)
		defer k8s.DeleteNamespace(GinkgoT(), options, namespaceName)
	})

	Context("when ingress resource is deployed using 'modsec-non-prod' ingress controller and modsec enabled", func() {
		It("should block the request if the url is malicious", func() {
			class := "modsec-non-prod"

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

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment-v1-default-cert.yaml.tmpl", "helloworld-deployment-v1-default-cert.yaml.tmpl", TemplateVars)
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

	Context("when a non-prod modsec ingress resource is deployed with an invalid modsecurity snippet", func() {
		It("should be rejected by the admission webhook", func() {
			class := "modsec-non-prod"

			setIdentifier := "integration-test-app-ing-" + namespaceName + "-green"

			TemplateVars := map[string]interface{}{
				"ingress_annotations": map[string]string{
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
				},
				"host":      host,
				"class":     class,
				"namespace": namespaceName,
			}

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-bad-modsec.yaml.tmpl", "helloworld-bad-modsec.yaml.tmpl", TemplateVars)
			if err != nil {
				Fail("Failed to create helloworld deployment template: " + err.Error())
			}

			tmpFile, err := os.CreateTemp("", "helloworld-bad-modsec-*.yaml")
			if err != nil {
				Fail("Failed to create temp file: " + err.Error())
			}
			defer os.Remove(tmpFile.Name())
			if _, err = tmpFile.WriteString(tpl); err != nil {
				Fail("Failed to write temp file: " + err.Error())
			}
			tmpFile.Close()

			var failures []string

			output, applyErr := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "apply", "-f", tmpFile.Name())
			if applyErr == nil {
				failures = append(failures, fmt.Sprintf("Expected admission webhook error denying the request\ngot: %s", output))
			} else {
				if !strings.Contains(applyErr.Error(), "admission webhook") {
					failures = append(failures, fmt.Sprintf("Expected error to contain 'admission webhook', got: %s", applyErr.Error()))
				}
				if !strings.Contains(applyErr.Error(), "validate.nginx.ingress.kubernetes.io") {
					failures = append(failures, fmt.Sprintf("Expected error to contain 'validate.nginx.ingress.kubernetes.io', got: %s", applyErr.Error()))
				}
				if !strings.Contains(applyErr.Error(), "modsecurity_rules") {
					failures = append(failures, fmt.Sprintf("Expected error to contain 'modsecurity_rules', got: %s", applyErr.Error()))
				}
			}

			By("Verifying ingress was not created")
			ingress, getErr := k8s.GetIngressE(GinkgoT(), options, "integration-test-app-ing")
			if getErr == nil {
				failures = append(failures, fmt.Sprintf("Expected ingress to not exist, but it was created: %s", ingress.Name))
			} else if !strings.Contains(getErr.Error(), "not found") {
				ingresses := k8s.ListIngresses(GinkgoT(), options, metav1.ListOptions{})
				var ingressNames []string
				for _, ing := range ingresses {
					ingressNames = append(ingressNames, ing.Name)
				}
				failures = append(failures, fmt.Sprintf("Expected 'not found' error but got: %s. Ingresses in namespace: %v", getErr.Error(), ingressNames))
			}

			if len(failures) > 0 {
				Fail(strings.Join(failures, "\n"))
			}
		})
	})
})
