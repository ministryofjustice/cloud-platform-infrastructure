package helpers

import (
	"fmt"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo/v2"
)

// HellowoldOpt type allows you to specify options for
// deploying a helloworld app template in a cluster.
type HelloworldOpt struct {
	Class      string `default:"default"`
	Identifier string `default:"integration-test-green"`
	Weight     string `default:"\"100\""`
	Hostname   string `example:"hostname.cloud-platform...."`
	Namespace  string `default:"default"`
}

// CreateHelloWorldApp takes a HelloworldOpt type and KubectlOptions arguments
// to create a HelloWorld app in the environment of your choice.
func CreateHelloWorldApp(app *HelloworldOpt, opt *k8s.KubectlOptions) error {
	if app.Hostname == "" {
		return fmt.Errorf("helloworld app hostname must not be empty")
	}

	templateVars := map[string]interface{}{
		"ingress_annotations": map[string]string{
			"external-dns.alpha.kubernetes.io/aws-weight":     app.Weight,
			"external-dns.alpha.kubernetes.io/set-identifier": app.Identifier,
		},
		"host":      app.Hostname,
		"class":     app.Class,
		"namespace": app.Namespace,
	}

	tpl, err := TemplateFile("./fixtures/helloworld-deployment-v1.yaml.tmpl", "helloworld-deployment-v1.yaml.tmpl", templateVars)
	if err != nil {
		return fmt.Errorf("failed to create the helloworld template: %s", err)
	}

	err = k8s.KubectlApplyFromStringE(GinkgoT(), opt, tpl)
	if err != nil {
		return fmt.Errorf("failed to apply the helloworld template: %s", err)
	}

	k8s.WaitUntilIngressAvailable(GinkgoT(), opt, "integration-test-app-ing", 60, 5*time.Second)

	return nil
}
