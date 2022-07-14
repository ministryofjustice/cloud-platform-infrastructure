package integration_tests

import (
	"flag"
	"fmt"
	"os"
	"testing"

	"github.com/sirupsen/logrus"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

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

// cluster lets you select which cluster to run the tests on
var cluster = flag.String("cluster", "", "Set the cluster name")

// TestMain controls pre/post test logic
func TestMain(m *testing.M) {
	flag.Parse()

	c = config.Config{
		Prefix: "smoketest",
	}

	err := c.SetClusterName(*cluster)
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
	RunSpecs(t, "Tests Suite")
}
