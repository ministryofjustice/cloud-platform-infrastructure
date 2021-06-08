package integration_tests

import (
	"flag"
	"os"
	"testing"

	"github.com/sirupsen/logrus"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/tiny-k8s-tester/pkg/config"
)

// c is global, so all tests has access to it
var c *config.Config

// Create a new instance of the logger. You can have any number of instances.
var log = logrus.New()

// configFile holds the path for the configuration file where test are declared
var configFile = flag.String("config", "./config.yaml", "Path for the configuration file where test are declared")

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
