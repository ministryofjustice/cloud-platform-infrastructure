package config

import (
	"context"
	"errors"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"

	"github.com/ministryofjustice/cloud-platform-go-library/client"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/util/homedir"
)

// Config holds the basic structure of test's YAML file
type Config struct {
	ClusterName             string                  `yaml:"clusterName"`
	Services                []string                `yaml:"expectedServices"`
	Daemonsets              []string                `yaml:"expectedDaemonSets"`
	ServiceMonitors         []string                `yaml:"expectedServiceMonitors"`
	Namespaces              map[string]K8SObjects   `yaml:"namespaces"`
}

	}
}

// SetClusterName is a setter method to define the name of the cluster to work on.
func (c *Config) SetClusterName(cluster string) error {
	var kubeconfig string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = filepath.Join(home, ".kube", "config")
	}

	if c.ClusterName == "" {
		k, err := client.NewKubeClientWithValues(kubeconfig, "")
		if err != nil {
			return fmt.Errorf("Unable to create kubeclient: %e", err)
		}
		nodes, err := k.Clientset.CoreV1().Nodes().List(context.Background(), metav1.ListOptions{})
		if err != nil {
			return fmt.Errorf("Unable to fetch node name: %e", err)
		}

		// All Cloud Platform clusters are tagged with the label Cluster=<ClusterName>.
		c.ClusterName = nodes.Items[0].Labels["Cluster"]
	}

	if c.ClusterName != "" {
		return nil
	}

	return errors.New("unable to locate cluster from kubeconfig file")
}

// ExpectedServices returns a slice of all the Services
// that are expected to be in the cluster.
func (c *Config) ExpectedServices() {
	// TODO: Add concourse to the list of expected services
	// Populate remaining services that exist in all clusters
	c.Services = append(c.Services, "cert-manager", "cert-manager-webhook", "prometheus-operated", "alertmanager-operated")
}

func (c *Config) ExpectedDaemonSets() {
	c.Daemonsets = append(c.Daemonsets, "fluent-bit", "prometheus-operator-prometheus-node-exporter")
}

func (c *Config) ExpectedServiceMonitors() {
	// if strings.Contains(strings.ToLower(c.ClusterName), "manager") {
	// 	c.ServiceMonitors = append(c.ServiceMonitors, "concourse")
	// }

	c.ServiceMonitors = append(c.ServiceMonitors, "cert-manager", "nginx-ingress-modsec-controller", "modsec01-nx-controller", "velero", "fluent-bit", "nginx-ingress-acme-ingress-nginx-controller", "nginx-ingress-default-controller", "fluent-bit", "prometheus-operator-prometheus-node-exporter", "prometheus-operated", "alertmanager-operated", "prometheus-operator-kube-p-alertmanager", "prometheus-operator-kube-p-apiserver", "prometheus-operator-kube-p-coredns", "prometheus-operator-kube-p-grafana", "prometheus-operator-kube-state-metrics", "prometheus-operator-kube-p-kubelet", "prometheus-operator-kube-p-prometheus", "prometheus-operator-kube-p-operator", "prometheus-operator-prometheus-node-exporter")
}

	}

}
