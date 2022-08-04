package integration_tests

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

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

// TestMain controls pre/post test logic
func TestMain(m *testing.M) {
	var kubeconfig *string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "(optional) absolute path to the kubeconfig file")
	}

	cluster := flag.String("cluster", "", "(optional) set the cluster name")
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

	// Cleanup all prefixed namespaces after the tests have finished.
	// I can't use AfterSuite here because it doesn't handle parallel tests.
	defer func() {
		if err := c.Cleanup(); err != nil {
			Fail(fmt.Sprintf("Failed to cleanup: %s", err))
		}
	}()

	os.Exit(exitVal)
}

// TestSpec runs all tests
func TestSpec(t *testing.T) {
	RegisterFailHandler(Fail)
	suiteConfig, reporterConfig := GinkgoConfiguration()
	suiteConfig.RandomizeAllSpecs = true
	suiteConfig.Timeout = 25 * time.Minute
	reporterConfig.FullTrace = true

	RunSpecs(t, "Tests Suite", suiteConfig, reporterConfig)
}
