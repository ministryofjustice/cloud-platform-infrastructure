package config

import (
	"context"
	"errors"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"strings"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-go-library/client"
	"gopkg.in/yaml.v2"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/util/homedir"
)

// ExternalDNS holds the config for externalDNS component
type ExternalDNS struct {
	NamespacePrefix string `yaml:"namespacePrefix"`
	HostedZoneId    string `yaml:"hostedZoneId"`
	Domain          string `yaml:"domain"`
}

// NginxIngressController holds the config for nginx ingress controller component
type NginxIngressController struct {
	NamespacePrefix string `yaml:"namespacePrefix"`
}
type ModsecIngressController struct {
	NamespacePrefix string `yaml:"namespacePrefix"`
}

// Config holds the basic structure of test's YAML file
type Config struct {
	ClusterName             string                  `yaml:"clusterName"`
	Services                []string                `yaml:"services"`
	DaemonSets              []string                `yaml:"daemonSets"`
	ServiceMonitors         []string                `yaml:"serviceMonitors"`
	Namespaces              map[string]K8SObjects   `yaml:"namespaces"`
	ExternalDNS             ExternalDNS             `yaml:"externalDNS"`
	NginxIngressController  NginxIngressController  `yaml:"nginxIngressController"`
	ModsecIngressController ModsecIngressController `yaml:"modsecIngressController"`
	FilesExist              []string                `yaml:"filesExist"`
}

// K8SObjects are kubernetes objects nested from namespaces, we need to check
// these resources are checked for its existence
type K8SObjects struct {
	Servicemonitors []string `yaml:"servicemonitors"`
	Daemonsets      []string `yaml:"daemonsets"`
	Services        []string `yaml:"services"`
	Secrets         []string `yaml:"secrets"`
}

// ParseConfigFile loads the test file supplied
func ParseConfigFile(f string) (*Config, error) {
	testsFilePath, err := ioutil.ReadFile(f)
	if err != nil {
		return nil, err
	}

	t := Config{}

	err = yaml.Unmarshal(testsFilePath, &t)
	if err != nil {
		return nil, err
	}

	return &t, nil
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
	c.DaemonSets = append(c.DaemonSets, "fluent-bit", "prometheus-operator-prometheus-node-exporter", "fake-daemonset")
}

func (c *Config) ExpectedServiceMonitors() {
	// if strings.Contains(strings.ToLower(c.ClusterName), "manager") {
	// 	c.ServiceMonitors = append(c.ServiceMonitors, "concourse")
	// }

	c.ServiceMonitors = append(c.ServiceMonitors, "cert-manager", "nginx-ingress-modsec-controller", "modsec01-nx-controller", "velero", "fluent-bit", "nginx-ingress-acme-ingress-nginx-controller", "nginx-ingress-default-controller", "fluent-bit", "prometheus-operator-prometheus-node-exporter", "prometheus-operated", "alertmanager-operated", "prometheus-operator-kube-p-alertmanager", "prometheus-operator-kube-p-apiserver", "prometheus-operator-kube-p-coredns", "prometheus-operator-kube-p-grafana", "prometheus-operator-kube-state-metrics", "prometheus-operator-kube-p-kubelet", "prometheus-operator-kube-p-prometheus", "prometheus-operator-kube-p-operator", "prometheus-operator-prometheus-node-exporter")
}

// GetNamespaceName returns random namespace name, it considers (if set) the prefix
// specified in the configuration
func (e *ExternalDNS) GetNamespaceName() string {
	if e.NamespacePrefix != "" {
		return fmt.Sprintf("%s%s", e.NamespacePrefix, strings.ToLower(random.UniqueId()))
	}

	return fmt.Sprintf("external-dns-test-%s", strings.ToLower(random.UniqueId()))
}
