package integration_tests

import (
	"crypto/tls"
	"fmt"
	"html/template"
	"strings"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/tests/pkg/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("cert-manager", func() {
	const (
		domain = "integrationtest.service.justice.gov.uk" // All clusters have access to the test domain name
	)

	Context("when the namespace has a certificate resource", func() {
		var (
			namespace = fmt.Sprintf("cert-smoketest-%v", strings.ToLower(random.UniqueId()))
			options   = k8s.NewKubectlOptions("", "", namespace)
			host      = fmt.Sprintf("%s.%s", namespace, domain)

			err  error
			cert []string
			// resp *http.Response
			conn *tls.Conn
		)

		BeforeEach(func() {
			k8s.CreateNamespace(GinkgoT(), options, namespace)
			app := helpers.HelloworldOpt{
				Hostname:   host,
				Class:      "nginx",
				Identifier: "integration-test-app-ing-" + namespace + "-green",
				Namespace:  namespace,
				Weight:     "\"100\"",
			}

			err = helpers.CreateHelloWorldApp(&app, options)
			Expect(err).NotTo(HaveOccurred())

			err = createCertificate(namespace, host, options)
			Expect(err).NotTo(HaveOccurred())
		})

		AfterEach(func() {
			k8s.DeleteNamespace(GinkgoT(), options, namespace)
		})

		FIt("should succeed and present a staging certificate", func() {
			conn, err = tls.Dial("tcp", host+":443", &tls.Config{InsecureSkipVerify: true})
			Expect(err).NotTo(HaveOccurred())
			cert = conn.ConnectionState().PeerCertificates[0].Issuer.Organization
			// resp, _ = http.Get("https://" + host)

			// defer resp.Body.Close()
			// defer conn.Close()

			Expect(cert[0]).To(Equal("(STAGING) Let's Encrypt"))
			// Expect(resp.StatusCode).To(Equal(200))
		})
	})
})

func createCertificate(namespace, host string, options *k8s.KubectlOptions) error {
	tpl, err := helpers.TemplateFile("./fixtures/certificate.yaml.tmpl", "certificate.yaml.tmpl", template.FuncMap{
		"certname":    namespace,
		"namespace":   namespace,
		"hostname":    host,
		"environment": "staging",
	})
	if err != nil {
		return err
	}

	err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
	if err != nil {
		return err
	}

	// err = waitForCertificateToBeReady(namespace, options)
	// if err != nil {
	// 	return err
	// }
	time.Sleep(160 * time.Second) // Wait for the certificate to be ready

	return nil
}

func waitForCertificateToBeReady(namespace string, options *k8s.KubectlOptions) error {
	// Wait 160 seconds for the certificate to be ready
	for i := 0; i < 160; i++ {
		err := k8s.RunKubectlE(GinkgoT(), options, "get", "certificate", namespace, "-o", "jsonpath={.status.conditions[?(@.type=='Ready')].status}")
		if err == nil {
			return nil
		}
		time.Sleep(1 * time.Second)
	}
	return nil
}
