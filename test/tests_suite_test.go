package integration_tests

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"testing"

	"github.com/sirupsen/logrus"
	"gopkg.in/yaml.v2"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/cloud-platform-go-library/client"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/config"
)

// All clusters have access to the test domain name
const testDomain = "integrationtest.service.justice.gov.uk"

// c is global, so all tests has access to it
var c *config.Config

// Create a new instance of the logger. You can have any number of instances.
var log = logrus.New()

// configFile holds the path for the configuration file where test are declared
var configFile = flag.String("config", "./config/config.yaml", "Path for the configuration file where test are declared")

// TestMain controls pre/post test logic
func TestMain(m *testing.M) {
	flag.Parse()
	config, err := config.ParseConfigFile(*configFile)
	if err != nil {
		log.Fatal(err)
	}

	// Set global variable
	c = config

	// Run tests
	exitVal := m.Run()

	os.Exit(exitVal)
}

// TestTests Rans the Ginkgo specs
func TestTests(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Tests Suite")
}

// Config holds the basic structure of test's YAML file
type Config struct {
	ClusterName             string                         `yaml:"clusterName"`
	Namespaces              map[string]K8SObjects          `yaml:"namespaces"`
	ExternalDNS             config.ExternalDNS             `yaml:"externalDNS"`
	NginxIngressController  config.NginxIngressController  `yaml:"nginxIngressController"`
	ModsecIngressController config.ModsecIngressController `yaml:"modsecIngressController"`
	FilesExist              []string                       `yaml:"filesExist"`
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

	err = t.defaultsFromEnvs()
	if err != nil {
		return nil, err
	}

	return &t, nil
}

// defaultsFromEnvs process the mandatory fields in the config. If they are not set,
// it tries to load them from environment variables
func (c Config) defaultsFromEnvs() error {
	clusterEnv := os.Getenv("CP_CLUSTER_NAME")
	if clusterEnv != "" {
		c.ClusterName = clusterEnv
	}

	if c.ClusterName == "" {
		k, err := client.NewKubeClientWithValues("", "")
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

// GetExpectedDaemonSets process the mandatory fields in the config. If they are not set,
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
