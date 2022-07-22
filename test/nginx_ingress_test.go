package integration_tests

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	. "github.com/onsi/ginkgo/v2"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
)

var _ = Describe("ingress-controllers", func() {
	var (
		namespaceName, host string
		options             *k8s.KubectlOptions
	)

	BeforeEach(func() {
		namespaceName = fmt.Sprintf("%s-ing-%s", c.Prefix, strings.ToLower(random.UniqueId()))
		host = fmt.Sprintf("%s.apps.%s.%s", namespaceName, c.ClusterName, domain)
		options = k8s.NewKubectlOptions("", "", namespaceName)

		err := k8s.CreateNamespaceE(GinkgoT(), options, namespaceName)
		Expect(err).ToNot(HaveOccurred())
	})

	AfterEach(func() {
		err := k8s.DeleteNamespaceE(GinkgoT(), options, namespaceName)
		Expect(err).ToNot(HaveOccurred())
	})

	Context("when an ingress resource is deployed using the 'nginx' ingress controller", func() {
		It("should expose the service to the internet", func() {
			setIdentifier := "integration-test-app-ing-" + namespaceName + "-green"

			TemplateVars := map[string]interface{}{
				"ingress_annotations": map[string]string{
					"kubernetes.io/ingress.class":                     "nginx",
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
				},
				"host":      host,
				"namespace": namespaceName,
			}

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment.yaml.tmpl", "helloworld-deployment.yaml.tmpl", TemplateVars)
			if err != nil {
				Fail(fmt.Sprintf("Failed to perform GET request, do you have a connection to the Internet? Error: %s", err.Error()))
			}

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			k8s.WaitUntilIngressAvailable(GinkgoT(), options, "integration-test-app-ing", 6, 20*time.Second)

			GinkgoWriter.Printf("Checking that the ingress is available at https://%s\n", host)
			Eventually(func() int {
				resp, err := http.Get("https://" + host)
				if err != nil {
					Fail(err.Error())
				}
				defer resp.Body.Close()
				return resp.StatusCode
			}, "8m", "30s").Should(Equal(200))

		})
	})

	Context("when an ingress resource is deployed using 'default' ingress controller", func() {
		FIt("should expose the service to the internet", func() {
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

			GinkgoWriter.Printf("Checking that the ingress is available at https://%s\n", host)
			Eventually(func() int {
				fmt.Println("Checking that the ingress is available at https://" + host)
				resp, err := http.Get("https://" + host)
				if err != nil {
					Fail("Failed to perform GET request, do you have a connection to the Internet? Error: " + err.Error())
				}
				fmt.Println("Response: ", resp.StatusCode)
				defer resp.Body.Close()
				return resp.StatusCode
			}, "8m", "30s").Should(Equal(200))
		})
	})
})
