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
		domain    = "raz-test.cloud-platform.service.justice.gov.uk"
		host      = fmt.Sprintf("%s.%s", namespace, domain)
	)

	BeforeEach(func() {
		k8s.CreateNamespace(GinkgoT(), options, namespace)

		// Create the application and ingress rule
		app := helpers.HelloworldOpt{
			Hostname:   host,
			Class:      "nginx",
			Identifier: namespace + "-integration-test" + "green",
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
		// defer k8s.DeleteNamespace(GinkgoT(), options, namespace)
	})

	Context("when a certificate resource is created", func() {
		FIt("should allow a TLS handshake \n", func() {
			c, err := tls.Dial("tcp", host+":443", nil)
			Expect(err).NotTo(HaveOccurred())

			time.Sleep(120 * time.Second)

		})

		// gomega validation
	})
})
