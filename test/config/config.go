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

// defaultsFromEnvs process the mandatory fields in the config. If they are not set,
// it tries to load them from environment variables
func (c *Config) GetExpectedDaemonSets() map[string][]string {
	r := make(map[string][]string)

	for ns, val := range c.Namespaces {
		var daemonSets []string

		daemonSets = append(daemonSets, val.Daemonsets...)

		if len(daemonSets) > 0 {
			r[ns] = daemonSets
		}
	}

	return r
}

// GetServiceMonitors process the mandatory fields in the config. If they are not set,
// it tries to load them from environment variables
func (c *Config) GetExpectedServiceMonitors() map[string][]string {
	r := make(map[string][]string)

	for ns, val := range c.Namespaces {
		var serviceMonitors []string

		serviceMonitors = append(serviceMonitors, val.Servicemonitors...)

		if len(serviceMonitors) > 0 {
			r[ns] = serviceMonitors
		}
	}

	return r
}

// GetExpectedServices returns a slice of all the services
// that are expected to be in the cluster.
func (c *Config) GetExpectedServices() map[string][]string {
	r := make(map[string][]string)

	for ns, val := range c.Namespaces {
		var services []string

		services = append(services, val.Services...)

		if len(services) > 0 {
			r[ns] = services
		}
	}

	return r
}

// GetNamespaceName returns random namespace name, it considers (if set) the prefix
// specified in the configuration
func (e *ExternalDNS) GetNamespaceName() string {
	if e.NamespacePrefix != "" {
		return fmt.Sprintf("%s%s", e.NamespacePrefix, strings.ToLower(random.UniqueId()))
	}

	return fmt.Sprintf("external-dns-test-%s", strings.ToLower(random.UniqueId()))
}
