package integration_tests

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

// DefaultCert is the struct of the default certificate used
// for wildcard certificates, such as *.apps.<host>
type DefaultCert struct {
	Spec struct {
		IssuerRef struct {
			Kind string `json:"kind"`
			Name string `json:"name"`
		} `json:"issuerRef"`
	} `json:"spec"`
	Status struct {
		Conditions []struct {
			Status string `json:"status"`
		} `json:"conditions"`
	} `json:"status"`
}

// Check if the default ingress-controller certificate exists
var _ = Describe("Default ingress-controller certificate", func() {
	options := k8s.NewKubectlOptions("", "", "ingress-controllers")

	// Get the default ingress-controller certificate
	certificate, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "certificate", "default", "-o", "json")
	Expect(err).ToNot(HaveOccurred())

	// Unmarshal the certificate
	var cert DefaultCert
	err = json.Unmarshal([]byte(certificate), &cert)
	Expect(err).ToNot(HaveOccurred())

	It("should be valid", func() {
		Expect(cert.Status.Conditions[0].Status).To(Equal("True"))
	})
	It("should be issued by the default issuer", func() {
		Expect(cert.Spec.IssuerRef.Kind).To(Equal("ClusterIssuer"))
		Expect(cert.Spec.IssuerRef.Name).To(Equal("letsencrypt-production"))
	})
})

// This test checks if a staging let's encrypt cert is assigned to an app
// It's less than ideal as it relies on the staging let's encrypt issuer
// responds in time. Eventually, we'll look to see if we can utilise
// https://github.com/letsencrypt/pebble.

// It includes FlakeAttempts to ensure that the test doesn't fail on the chance
// of a slow acme response.
var _ = Describe("cert-manager", FlakeAttempts(3), func() {
	Context("when the namespace has a certificate resource", func() {
		var (
			namespace, host string
			options         *k8s.KubectlOptions

			err  error
			cert []string
			conn *tls.Conn
		)

		BeforeEach(func() {
			namespace = fmt.Sprintf("%s-certman-%s", c.Prefix, strings.ToLower(random.UniqueId()))
			options = k8s.NewKubectlOptions("", "", namespace)
			host = fmt.Sprintf("%s.%s", namespace, testDomain)
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

			err = helpers.CreateCertificate(namespace, host, options)
			Expect(err).NotTo(HaveOccurred())

			GinkgoWriter.Printf("Checking the certificate is valid")
			Eventually(func() bool {
				certificate, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "certificate", "-o", "json")
				Expect(err).ToNot(HaveOccurred())

				var cert DefaultCert
				err = json.Unmarshal([]byte(certificate), &cert)
				Expect(err).ToNot(HaveOccurred())

				return cert.Status.Conditions[0].Status == "True"
			}, "5m", "1m").Should(BeTrue())
		})

		AfterEach(func() {
			k8s.DeleteNamespace(GinkgoT(), options, namespace)
		})

		FIt("should succeed and present a staging certificate", func() {
			Eventually(func() string {
				conn, err = tls.Dial("tcp", host+":443", &tls.Config{InsecureSkipVerify: true})
				Expect(err).NotTo(HaveOccurred())
				cert = conn.ConnectionState().PeerCertificates[0].Issuer.Organization
				return cert[0]
			}, "3m", "30s").Should(Equal("(STAGING) Let's Encrypt"))
		})
	})
})
