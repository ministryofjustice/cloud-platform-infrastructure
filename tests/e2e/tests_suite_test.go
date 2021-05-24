package integration_tests

import (
	"log"
	"os"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/tiny-k8s-tester/pkg/config"
)

// c is global, so all tests has access to it
var c *config.Config

// TestMain controls pre/post test logic
func TestMain(m *testing.M) {
	config, err := config.ParseConfigFile("./config.yaml")
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
