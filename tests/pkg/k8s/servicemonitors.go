package k8s

import (
	"context"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/tools/clientcmd"

	"github.com/pkg/errors"
	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/testing"
	v1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
	prom "github.com/prometheus-operator/prometheus-operator/pkg/client/versioned/typed/monitoring/v1"
)

// GetServiceMonitorSet returns a serviceMonitor resource in the provided namespace with the given name. This will
// fail the test if there is an error.
func GetServiceMonitorSet(t testing.TestingT, options *k8s.KubectlOptions, serviceMonitorName string) *v1.ServiceMonitor {
	servicemonitor, err := GetServiceMonitorSetE(t, options, serviceMonitorName)
	require.NoError(t, err)
	return servicemonitor
}

// GetServiceMonitorSetE returns a serviceMonitor resource in the provided namespace with the given name.
func GetServiceMonitorSetE(t testing.TestingT, options *k8s.KubectlOptions, serviceMonitorName string) (*v1.ServiceMonitor, error) {

	var err error

	kubeConfigPath, err := options.GetConfigPath(t)
	if err != nil {
		return nil, err
	}

	config, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
	if err != nil {
		return nil, errors.Wrap(err, "build config from flags failed")
	}

	client, err := prom.NewForConfig(config)
	if err != nil {
		return nil, errors.Wrap(err, "creating v1 monitoring client failed")
	}
	return client.ServiceMonitors(options.Namespace).Get(context.Background(), serviceMonitorName, metav1.GetOptions{})
}
