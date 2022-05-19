package helpers

import (
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/testing"
	"github.com/pkg/errors"
	prom "github.com/prometheus-operator/prometheus-operator/pkg/client/versioned/typed/monitoring/v1"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

// GetClientConfig returns a Kubernetes API clientset given a configured KubectlOptions object.
func GetClientConfigE(t testing.TestingT, options *k8s.KubectlOptions) (*rest.Config, error) {
	var err error
	var config *rest.Config

	kubeConfigPath, err := options.GetConfigPath(t)
	if err != nil {
		return nil, err
	}

	config, err = clientcmd.BuildConfigFromFlags("", kubeConfigPath)
	if err != nil {
		return nil, errors.Wrap(err, "build config from flags failed")
	}
	return config, nil
}

func GetPrometheusClientSetE(t testing.TestingT, options *k8s.KubectlOptions) (*prom.MonitoringV1Client, error) {
	config, err := GetClientConfigE(t, options)
	if err != nil {
		return nil, err
	}
	client, err := prom.NewForConfig(config)
	if err != nil {
		return nil, errors.Wrap(err, "creating v1 monitoring client failed")
	}
	return client, nil
}
