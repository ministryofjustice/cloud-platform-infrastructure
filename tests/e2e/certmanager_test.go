package integration_tests

import (
	"crypto/tls"
	"errors"
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
		// All clusters have access to the test domain name
		domain = "integrationtest.service.justice.gov.uk"
	)

	Context("when the namespace has a certificate resource", func() {
		var (
			namespace = fmt.Sprintf("cert-smoketest-%v", strings.ToLower(random.UniqueId()))
			options   = k8s.NewKubectlOptions("", "", namespace)
			host      = fmt.Sprintf("%s.%s", namespace, domain)

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

			Expect(cert[0]).To(Equal("(STAGING) Let's Encrypt"))
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

	err = waitForCertificateToBeReady(namespace, options, 200)
	if err != nil {
		return err
	}

	return nil
}

func waitForCertificateToBeReady(namespace string, options *k8s.KubectlOptions, retries int) error {
	fmt.Printf("Waiting for certificate %s to be ready %v times\n", namespace, retries)

	for i := 0; i < retries; i++ {
		fmt.Println("Checking certificate status: attempt" + fmt.Sprintf("%v", i+1))
		status, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "certificate", namespace, "-o", "jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}'")
		if err != nil {
			return errors.New("Certificate creation failed")
		}
		fmt.Println("status:", status)
		if status == "'True'" {
			return nil
		}

		time.Sleep(5 * time.Second)
	}
	return fmt.Errorf("Certificate %s is not ready", namespace)
}

// func WaitUntilIngressAvailableV1Beta1(t testing.TestingT, options *k8s.KubectlOptions, ingressName string, retries int, sleepBetweenRetries time.Duration) {
// 	statusMsg := fmt.Sprintf("Wait for ingress %s to be provisioned.", ingressName)
// 	message := retry.DoWithRetry(
// 		t,
// 		statusMsg,
// 		retries,
// 		sleepBetweenRetries,
// 		func() (string, error) {
// 			ingress, err := GetIngressV1Beta1E(t, options, ingressName)
// 			if err != nil {
// 				return "", err
// 			}
// 			if !IsIngressAvailableV1Beta1(ingress) {
// 				return "", IngressNotAvailableV1Beta1{ingress: ingress}
// 			}
// 			return "Ingress is now available", nil
// 		},
// 	)
// 	logger.Logf(t, message)
// }
