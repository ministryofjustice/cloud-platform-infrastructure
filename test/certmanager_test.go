package integration_tests

import (
	"crypto/tls"
	"fmt"
	"strings"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("cert-manager", func() {
	Context("when the namespace has a certificate resource", func() {
		var (
			namespace = fmt.Sprintf("smoketest-certman-%s", strings.ToLower(random.UniqueId()))
			options   = k8s.NewKubectlOptions("", "", namespace)
			host      = fmt.Sprintf("%s.%s", namespace, testDomain)

			err  error
			cert []string
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

			err = helpers.CreateCertificate(namespace, host, options)
			Expect(err).NotTo(HaveOccurred())
		})

		AfterEach(func() {
			k8s.DeleteNamespace(GinkgoT(), options, namespace)
		})

		It("should succeed and present a staging certificate", func() {
			conn, err = tls.Dial("tcp", host+":443", &tls.Config{InsecureSkipVerify: true})
			Expect(err).NotTo(HaveOccurred())
			cert = conn.ConnectionState().PeerCertificates[0].Issuer.Organization

			time.Sleep(60 * time.Second)

			Expect(cert[0]).To(Equal("(STAGING) Let's Encrypt"))
		})
	})
})
