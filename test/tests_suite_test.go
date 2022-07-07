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
	testDomain = "integrationtest.service.justice.gov.uk"
	domain     = "cloud-platform.service.justice.gov.uk"
)

const hostedZoneId = "Z02429076QQMAO8KXV68"

// c is global, so all tests has access to it
var c *config.Config

// Create a new instance of the logger. You can have any number of instances.
var log = logrus.New()

// configFile holds the path for the configuration file where test are declared
var (
	configFile = flag.String("config", "./config/config.yaml", "Path for the configuration file where test are declared")
	cluster    = flag.String("cluster", "", "Set the cluster name")
)

// TestMain controls pre/post test logic
func TestMain(m *testing.M) {
	flag.Parse()

	var err error
	// TODO: Remove configfile location
	c, err = config.ParseConfigFile(*configFile)
	if err != nil {
		log.Fatal(err)
	}

	err = c.SetClusterName(*cluster)
	if err != nil {
		log.Fatal(err)
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
