package integration_tests

import (
	"fmt"
	"html/template"
	"log"
	"strings"
	"time"

	. "github.com/onsi/ginkgo"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/tiny-k8s-tester/pkg/helpers"
)

var _ = Describe("Nginx Ingress", func() {
	var (
		currentCluster = c.ClusterName
		namespaceName  = fmt.Sprintf("smoketest-ingress-%s", strings.ToLower(random.UniqueId()))
		host           = fmt.Sprintf("%s-nginx.apps.%s", namespaceName, currentCluster)
		options        = k8s.NewKubectlOptions("", "", namespaceName)
		url            = fmt.Sprintf("https://%s", host)
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

	Context("when ingress resource is deployed using 'nginx' ingress controller", func() {
		It("should expose the service to the internet", func() {
			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment.yaml.tmpl", "helloworld-deployment.yaml.tmpl", template.FuncMap{
				"ingress_class": "nginx",
				"host":          host,
			})
			if err != nil {
				log.Fatalf("execution: %s", err)
			}

			k8s.KubectlApplyFromString(GinkgoT(), options, tpl)
			k8s.WaitUntilIngressAvailableV1Beta1(GinkgoT(), options, "integration-test-app-ing", 60, 5*time.Second)

			retry.DoWithRetry(GinkgoT(), fmt.Sprintf("Waiting for sucessfull DNS lookup from %s", host), 20, 10*time.Second, func() (string, error) {
				return helpers.DNSLookUp(host)
			})

			Expect(helpers.HttpStatusCode(url)).To(Equal(200))
		})
	})
})
