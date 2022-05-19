package integration_tests

import (
	"fmt"
	"strings"
	"time"

	. "github.com/onsi/ginkgo"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/cloud-platform-infrastructure/test/config"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
)

var _ = Describe("Modsec Ingress", func() {
	var (
		currentCluster = c.ClusterName
		namespaceName  = fmt.Sprintf("smoketest-modsec-%s", strings.ToLower(random.UniqueId()))
		host           = fmt.Sprintf("%s.apps.%s", namespaceName, currentCluster)
		options        = k8s.NewKubectlOptions("", "", namespaceName)
		url            = fmt.Sprintf("https://%s", host)
		good_url       = fmt.Sprintf("https://%s", host)
		bad_url        = fmt.Sprintf("%s?exec=/bin/bash", url)
		tpl            string
	)

	BeforeEach(func() {
		if (config.ModsecIngressController{}) == c.ModsecIngressController {
			Skip("Modsec Ingress Controller component not defined, skipping test")
		}

		By("not having an ingress resource deployed")

		Expect(helpers.HttpStatusCode(url)).To(Equal(404))

		k8s.CreateNamespace(GinkgoT(), options, namespaceName)
	})

	AfterEach(func() {
		defer k8s.KubectlDeleteFromString(GinkgoT(), options, tpl)
		defer k8s.DeleteNamespace(GinkgoT(), options, namespaceName)
	})

	Context("when ingress resource is deployed using 'modsec' ingress controller and modsec enabled", func() {
		It("should block the request if the url is malicious", func() {
			var err error

			setIdentifier := "integration-test-app-ing-" + namespaceName + "-green"

			TemplateVars := map[string]interface{}{
				"ingress_annotations": map[string]string{
					"kubernetes.io/ingress.class":                     "modsec01",
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
					"nginx.ingress.kubernetes.io/enable-modsecurity":  "\"true\"",
					"nginx.ingress.kubernetes.io/modsecurity-snippet": "|\n     SecRuleEngine On",
				},
				"host": host,
			}

			tpl, err = helpers.TemplateFile("./fixtures/helloworld-deployment.yaml.tmpl", "helloworld-deployment.yaml.tmpl", TemplateVars)
			if err != nil {
				log.Fatalf("execution: %s", err)
			}

			k8s.KubectlApplyFromString(GinkgoT(), options, tpl)
			k8s.WaitUntilIngressAvailableV1Beta1(GinkgoT(), options, "integration-test-app-ing", 60, 5*time.Second)

			retry.DoWithRetry(GinkgoT(), fmt.Sprintf("evaluating http code for %s", host), 2, 120*time.Second, func() (string, error) {
				s, err := helpers.HttpStatusCode(url)
				if err != nil {
					log.Fatalf("execution: %s", err)
				}

				if s != 200 {
					return "", fmt.Errorf("Expected http return code 200. Got '%v'", s)
				}
				return "", nil
			})

			// This is not ideal, we need to find the way how improve this.
			time.Sleep(120 * time.Second)

			Expect(helpers.HttpStatusCode(bad_url)).To(Equal(403))

			By("having an benign url, request succeeds")

			Expect(helpers.HttpStatusCode(good_url)).To(Equal(200))
		})
	})
})
