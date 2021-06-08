package tests

import (
	"context"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/pkg/errors"
	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/testing"
	prom "github.com/prometheus-operator/prometheus-operator/pkg/client/versioned/typed/monitoring/v1"
)

// GetServiceMonitorSet returns a serviceMonitor resource in the provided namespace with the given name. This will
// fail the test if there is an error.
func GetServiceMonitorSet(t testing.TestingT, options *KubectlOptions, serviceMonitorName string) []*prom.ServiceMonitor {
	servicemonitor, err := GetServiceMonitorSetE(t, options, serviceMonitorName)
	require.NoError(t, err)
	return servicemonitor
}

// GetServiceMonitorSetE returns a serviceMonitor resource in the provided namespace with the given name.
func GetServiceMonitorSetE(t testing.TestingT, options *KubectlOptions, serviceMonitorName string) ([]*prom.ServiceMonitor, error) {

	var err error
	// var config *rest.Config

	kubeConfigPath, err := options.GetConfigPath(t)
	if err != nil {
		return nil, err
	}

	client, err := prom.NewForConfig(kubeConfigPath)
	if err != nil {
		return nil, errors.Wrap(err, "creating v1 monitoring client failed")
	}
	return client.ServiceMonitors(options.Namespace).List(context.Background(), serviceMonitorName, metav1.GetOptions{})
}
