package integration_tests

import (
	"fmt"
	"html/template"
	"math/rand"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/ministryofjustice/cloud-platform-infrastructure/tests/pkg/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("cert-manager", func() {
	var (
		namespace = fmt.Sprintf("cert-manager-test-%v", rand.Int())
		options   = k8s.NewKubectlOptions("", "", namespace)
		host      = fmt.Sprintf("https://%s.%v", namespace, c.ClusterName)
	)

	BeforeEach(func() {
		k8s.CreateNamespace(GinkgoT(), options, namespace)

		app := helpers.HelloworldOpt{
			Hostname: host,
		}

		err := helpers.CreateHelloWorldApp(&app, options)
		Expect(err).NotTo(HaveOccurred())

		tpl, err := helpers.TemplateFile("./fixtures/certificate.yaml.tmpl", "cert.yaml.tmpl", template.FuncMap{
			"cert-name":   namespace,
			"namespace":   namespace,
			"hostname":    host,
			"environment": "staging",
		})

		err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
		Expect(err).NotTo(HaveOccurred())
	})

	AfterEach(func() {
		defer k8s.DeleteNamespace(GinkgoT(), options, namespace)
		// destroy ingress resource
		// destroy namespace
	})

	Context("when a certificate resource is created", func() {
		// validate_certificate
		// gomega validation
	})
})
