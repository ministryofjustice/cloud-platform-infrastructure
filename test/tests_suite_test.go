package integration_tests

import (
	"flag"
	"fmt"
	"os"
	"testing"
	"time"

	. "github.com/onsi/ginkgo/v2"
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
var (
	c config.Config
	// log = zerolog.New(GinkgoWriter).With().Str("cluster", c.ClusterName).Logger()
)

// TestMain controls pre/post test logic
func TestMain(m *testing.M) {
	// debug := flag.Bool("debug", false, "sets log level to debug")
	// cluster lets you select which cluster to run the tests on
	cluster := flag.String("cluster", "", "Set the cluster name")
	flag.Parse()

	c = config.Config{
		Prefix: "smoketest",
	}
	// setupLogging(*debug)

	err := c.SetClusterName(*cluster)
	if err != nil {
		Fail(fmt.Sprintf("Failed to set cluster name: %s", err))
	}

	// Run tests
	fmt.Println("Running tests on cluster: ", c.ClusterName)
	exitVal := m.Run()

	os.Exit(exitVal)
}

// TestTests Rans the Ginkgo specs
func TestTests(t *testing.T) {
	RegisterFailHandler(Fail)

	suiteConfig, reporterConfig := GinkgoConfiguration()
	suiteConfig.RandomizeAllSpecs = true
	suiteConfig.Timeout = 40 * time.Minute
	suiteConfig.EmitSpecProgress = true
	suiteConfig.FailFast = false
	suiteConfig.FlakeAttempts = 3
	suiteConfig.EmitSpecProgress = true
	suiteConfig.ParallelTotal = 3

	reporterConfig.NoColor = false
	reporterConfig.SlowSpecThreshold = 120 * time.Second
	reporterConfig.Verbose = false
	reporterConfig.Succinct = true
	reporterConfig.FullTrace = false

	GinkgoWriter.TeeTo(os.Stdout)
	RunSpecs(t, "Running integration tests in cluster")
}
