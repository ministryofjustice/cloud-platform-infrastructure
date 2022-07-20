package integration_tests

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/sirupsen/logrus"
	"k8s.io/client-go/util/homedir"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/cloud-platform-go-library/client"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/config"
)

// All clusters have access to the test domain name and their own domain name
const (
	testDomain   = "integrationtest.service.justice.gov.uk"
	domain       = "cloud-platform.service.justice.gov.uk"
	hostedZoneId = "Z02429076QQMAO8KXV68"
)

// // c is global, so all tests has access to it
var c config.Config

// Create a new instance of the logger. You can have any number of instances.
var log = logrus.New()

// TestMain controls pre/post test logic
func TestMain(m *testing.M) {
	var kubeconfig *string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	}

	var cluster = flag.String("cluster", "", "(optional) set the cluster name")
	flag.Parse()

	client, err := client.NewKubeClientWithValues(*kubeconfig, "")
	if err != nil {
		Fail(fmt.Sprintf("Failed to create kube client: %v", err))
	}

	c = config.Config{
		Prefix: "smoketest",
		Client: *client,
	}

	err = c.SetClusterName(*cluster)
	if err != nil {
		Fail(fmt.Sprintf("Failed to set cluster name: %s", err))
	}

	// Run tests
	fmt.Printf("Starting tests on cluster: %s\n", c.ClusterName)
	exitVal := m.Run()

	os.Exit(exitVal)
}

// TestTests Rans the Ginkgo specs
func TestTests(t *testing.T) {
	RegisterFailHandler(Fail)
	suiteConfig, reporterConfig := GinkgoConfiguration()
	suiteConfig.RandomizeAllSpecs = true
	reporterConfig.FullTrace = true
	RunSpecs(t, "Tests Suite")
}
