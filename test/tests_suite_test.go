package integration_tests

import (
	"flag"
	"fmt"
	"io"
	"os"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"github.com/ministryofjustice/cloud-platform-infrastructure/test/config"
)

type GinkgoWriterHack interface {
	AndRedirectTo(writer io.Writer)
}

// All clusters have access to the test domain name and their own domain name
const (
	testDomain   = "integrationtest.service.justice.gov.uk"
	domain       = "cloud-platform.service.justice.gov.uk"
	hostedZoneId = "Z02429076QQMAO8KXV68"
)

// c is global, so all tests has access to it
var c config.Config

// TestMain controls pre/post test logic
func TestMain(m *testing.M) {
	// cluster lets you select which cluster to run the tests on
	cluster := flag.String("cluster", "", "Set the cluster name")
	debug := flag.Bool("debug", false, "sets log level to debug")

	flag.Parse()

	c = config.Config{
		Prefix: "smoketest",
	}

	setupLogging(*debug)

	err := c.SetClusterName(*cluster)
	if err != nil {
		Fail(fmt.Sprintf("Failed to set cluster name: %s", err))
	}

	// Run tests
	log.Info().Msgf("Running tests on cluster: %s", c.ClusterName)
	exitVal := m.Run()

	os.Exit(exitVal)
}

// TestTests Rans the Ginkgo specs
func TestTests(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Tests Suite")
}

// setupLogging configures the zerolog package depending on arguments passed to it
func setupLogging(debug bool) {
	// Deafault log level is info
	zerolog.SetGlobalLevel(zerolog.InfoLevel)

	// Set colour output
	log.Logger = log.Output(zerolog.ConsoleWriter{
		Out:        os.Stderr,
		TimeFormat: zerolog.TimeFormatUnix,
		NoColor:    false,
	})

	// Set log level to debug if requested
	if debug {
		zerolog.SetGlobalLevel(zerolog.DebugLevel)
		log.Debug().Msg("Debug logging enabled")
	}
}
