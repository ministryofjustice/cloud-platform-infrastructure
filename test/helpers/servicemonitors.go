package helpers

import (
	"context"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/testing"
	v1 "github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/v1"
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
	client, err := GetPrometheusClientSetE(t, options)
	if err != nil {
		return nil, err
	}
	return client.ServiceMonitors(options.Namespace).Get(context.Background(), serviceMonitorName, metav1.GetOptions{})
}
