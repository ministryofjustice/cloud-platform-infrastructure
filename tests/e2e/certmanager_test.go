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
	var (
		namespace = fmt.Sprintf("cert-test-%v", strings.ToLower(random.UniqueId()))
		options   = k8s.NewKubectlOptions("", "", namespace)
		domain    = "integrationtest.service.justice.gov.uk"
		host      = fmt.Sprintf("%s.%s", namespace, domain)
	)

	BeforeEach(func() {
		k8s.CreateNamespace(GinkgoT(), options, namespace)

		// Create the application and ingress rule
		app := helpers.HelloworldOpt{
			Hostname:   host,
			Class:      "nginx",
			Identifier: namespace + "-integration-test-" + "green",
			Namespace:  namespace,
			Weight:     "\"100\"",
		}

		err := helpers.CreateHelloWorldApp(&app, options)
		Expect(err).NotTo(HaveOccurred())

		// Create the certificate resource
		tpl, err := helpers.TemplateFile("./fixtures/certificate.yaml.tmpl", "certificate.yaml.tmpl", template.FuncMap{
			"certname":    namespace,
			"namespace":   namespace,
			"hostname":    host,
			"environment": "staging",
		})
		Expect(err).NotTo(HaveOccurred())

		err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
		Expect(err).NotTo(HaveOccurred())
	})

	AfterEach(func() {
		defer k8s.DeleteNamespace(GinkgoT(), options, namespace)
	})

	Context("when a certificate resource is created", func() {
		FIt("should return the correct certificate name", func() {
			// time.Sleep(160 * time.Second) // Wait for the certificate to be ready
			waitForCertificate(options, namespace, 120)

			conn, err := tls.Dial("tcp", host+":443", &tls.Config{InsecureSkipVerify: true})
			Expect(err).NotTo(HaveOccurred())

			defer conn.Close()

			cert := conn.ConnectionState().PeerCertificates[0].Issuer.Organization

			Expect(cert[0]).To(Equal("(STAGING) Let's Encrypt"))
		})

		// gomega validation
	})
})

func waitForCertificate(options *k8s.KubectlOptions, namespace string, seconds int) string {
	var status string
	for i := 0; i < 12; i++ {
		status, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "certificate", namespace, "-o", "jsonpath='{.items[*].status.conditions[?(@.type==\"Ready\")].status}'")
		Expect(err).NotTo(HaveOccurred())

		fmt.Println(status)
		if status == "True" {
			break
		}
		time.Sleep(10 * time.Second)
		fmt.Println("Waiting for certificate to be ready")
	}

	return status
}
