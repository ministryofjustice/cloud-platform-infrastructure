package helpers

import (
	"text/template"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo/v2"
)

// CreateCertificate creates a certificate resource in the specified namespace.
func CreateCertificate(namespace, host, environment string, options *k8s.KubectlOptions) error {
	tpl, err := TemplateFile("./fixtures/certificate.yaml.tmpl", "certificate.yaml.tmpl", template.FuncMap{
		"certname":    namespace,
		"namespace":   namespace,
		"hostname":    host,
		"environment": environment,
	})
	if err != nil {
		return err
	}

	err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
	if err != nil {
		return err
	}

	return nil
}
