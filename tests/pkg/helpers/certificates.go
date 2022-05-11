package helpers

import (
	"fmt"
	"text/template"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo"
	"github.com/pkg/errors"
)

// CreateCertificate creates a certificate resource in the specified namespace.
func CreateCertificate(namespace, host string, options *k8s.KubectlOptions) error {
	tpl, err := TemplateFile("./fixtures/certificate.yaml.tmpl", "certificate.yaml.tmpl", template.FuncMap{
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

	// Wait for the certificate 20 times, with a 20 second sleep between each check
	err = WaitForCertificateToBeReady(namespace, options, 20, 20)
	if err != nil {
		return err
	}

	return nil
}

// WaitForCertificateToBeReady takes a certificate name and KubectlOptions arguments along with an along
// with an appropriate number of retries. It will wait until the certificate returns a status of Ready.
// The time between retries is specified by the retryInterval argument.
// If the certificate does not return a status of Ready after the specified number of retries, an error is returned.
func WaitForCertificateToBeReady(certName string, options *k8s.KubectlOptions, retries, retryInterval int) error {
	fmt.Printf("Waiting for certificate %s to be ready %v times\n", certName, retries)

	for i := 0; i < retries; i++ {
		fmt.Println("Checking certificate status: attempt: " + fmt.Sprintf("%v", i+1))
		status, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "certificate", certName, "-o", "jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}'")
		if err != nil {
			return errors.New("Certificate creation failed")
		}
		if status == "'True'" {
			return nil
		}

		fmt.Printf("Failed to validate certificate %s, sleeping for %v seconds\n", certName, retryInterval)
		time.Sleep(time.Duration(retryInterval) * time.Second)
	}
	return fmt.Errorf("certificate %s is not ready", certName)
}
