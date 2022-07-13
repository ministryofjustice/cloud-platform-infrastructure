package config

import (
	"context"
	"errors"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/ministryofjustice/cloud-platform-go-library/client"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/util/homedir"
)

// Config holds the basic structure of test's YAML file
type Config struct {
	ClusterName     string              `yaml:"clusterName"`
	Services        []string            `yaml:"expectedServices"`
	Daemonsets      []string            `yaml:"expectedDaemonSets"`
	ServiceMonitors map[string][]string `yaml:"expectedServiceMonitors"`
	Namespaces      []string            `yaml:"namespaces"`
}

// NewConfig returns a new Config with values passed in.
func NewConfig(clusterName string, services []string, daemonsets []string, serviceMonitors map[string][]string, namespaces []string) *Config {
	return &Config{
		ClusterName:     clusterName,
		Services:        services,
		Daemonsets:      daemonsets,
		ServiceMonitors: serviceMonitors,
		Namespaces:      namespaces,
	}
}

// SetClusterName is a setter method to define the name of the cluster to work on.
func (c *Config) SetClusterName(cluster string) error {
	var kubeconfig string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = filepath.Join(home, ".kube", "config")
	}

	if cluster == "" {
		k, err := client.NewKubeClientWithValues(kubeconfig, "")
		if err != nil {
			return fmt.Errorf("Unable to create kubeclient: %e", err)
		}

		nodes, err := k.Clientset.CoreV1().Nodes().List(context.Background(), metav1.ListOptions{})
		if err != nil {
			return fmt.Errorf("Unable to fetch node name: %e", err)
		}

		clusterName := nodes.Items[0].Labels["Cluster"]

		// All Cloud Platform clusters are tagged with the label Cluster=<ClusterName>.
		c.ClusterName = clusterName
	}

	if c.ClusterName != "" {
		return nil
	}

	return errors.New("unable to locate cluster from kubeconfig file")
}

// ExpectedNamespaces returns a slice of all the namespaces
// that are expected to be in the cluster.
func (c *Config) ExpectedNamespaces() {
	c.Namespaces = append(c.Namespaces, "cert-manager", "ingress-controllers", "logging", "monitoring", "opa", "velero")
}

// ExpectedServices returns a slice of all the Services
// that are expected to be in the cluster.
func (c *Config) ExpectedServices() {
	if strings.Contains(strings.ToLower(c.ClusterName), "manager") {
		c.Services = append(c.Services, "concourse")
	}

	// Populate remaining services that exist in all clusters
	c.Services = append(c.Services, "cert-manager", "cert-manager-webhook", "prometheus-operated", "alertmanager-operated")
}

func (c *Config) ExpectedDaemonSets() {
	c.Daemonsets = append(c.Daemonsets, "fluent-bit", "prometheus-operator-prometheus-node-exporter")
}

func (c *Config) ExpectedServiceMonitors() {
	// serviceMonitors describes all the service monitors that are expected to be in the cluster and their
	// accompanying namespaces.
	var serviceMonitors = map[string][]string{
		// NamespaceName: []Services
		"cert-manager": {"cert-manager"},

		"ingress-controllers": {"nginx-ingress-modsec-controller", "modsec01-nx-controller", "velero", "fluent-bit", "nginx-ingress-acme-ingress-nginx-controller", "nginx-ingress-default-controller"},

		"logging": {"fluent-bit"},

		"monitoring": {"prometheus-operator-prometheus-node-exporter", "prometheus-operated", "alertmanager-operated", "prometheus-operator-kube-p-alertmanager", "prometheus-operator-kube-p-apiserver", "prometheus-operator-kube-p-coredns", "prometheus-operator-kube-p-grafana", "prometheus-operator-kube-state-metrics", "prometheus-operator-kube-p-kubelet", "prometheus-operator-kube-p-prometheus", "prometheus-operator-kube-p-operator", "prometheus-operator-prometheus-node-exporter"},
	}

	if strings.Contains(strings.ToLower(c.ClusterName), "manager") {
		serviceMonitors["concourse"] = []string{"concourse"}
	}

	c.ServiceMonitors = serviceMonitors
}
