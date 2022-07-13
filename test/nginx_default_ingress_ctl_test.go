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

	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
)

var _ = Describe("Nginx Default Ingress v1", func() {
	var (
		currentCluster = c.ClusterName
		namespaceName  = fmt.Sprintf("smoketest-ingress-v1-%s", strings.ToLower(random.UniqueId()))
		host           = fmt.Sprintf("%s-nginx.apps.%s.%s", namespaceName, currentCluster, domain)
		options        = k8s.NewKubectlOptions("", "", namespaceName)
		url            = fmt.Sprintf("https://%s", host)
		class          = "default"
		tpl            string
	)

	BeforeEach(func() {
		By("not having an ingress resource deployed")

		Expect(helpers.HttpStatusCode(url)).To(Equal(404))

		k8s.CreateNamespace(GinkgoT(), options, namespaceName)
	})

	AfterEach(func() {
		defer k8s.KubectlDeleteFromString(GinkgoT(), options, tpl)
		defer k8s.DeleteNamespace(GinkgoT(), options, namespaceName)
	})

	Context("when ingress resource is deployed using 'default' ingress controller", func() {
		It("should expose the service to the internet", func() {
			var err error

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

			tpl, err = helpers.TemplateFile("./fixtures/helloworld-deployment-v1.yaml.tmpl", "helloworld-deployment-v1.yaml.tmpl", TemplateVars)
			if err != nil {
				log.Fatalf("execution: %s", err)
			}

			k8s.KubectlApplyFromString(GinkgoT(), options, tpl)
			k8s.WaitUntilIngressAvailableV1Beta1(GinkgoT(), options, "integration-test-app-ing", 60, 5*time.Second)

			retry.DoWithRetry(GinkgoT(), fmt.Sprintf("evaluating http code for %s", host), 20, 10*time.Second, func() (string, error) {
				s, err := helpers.HttpStatusCode(url)
				if err != nil {
					log.Fatalf("execution: %s", err)
				}

				if s != 200 {
					return "", fmt.Errorf("Expected http return code 200. Got '%v'", s)
				}
				return "", nil
			})

			// Sleep for 60 seconds
			time.Sleep(60 * time.Second)

			Expect(helpers.HttpStatusCode(url)).To(Equal(200))
		})
	})
})
