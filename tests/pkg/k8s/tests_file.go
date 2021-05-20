package tests

import (
	"fmt"
	"io/ioutil"
	"strings"
	"testing"

	"github.com/davecgh/go-spew/spew"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"gopkg.in/yaml.v3"

	"github.com/onsi/ginkgo"
)

var Describe = ginkgo.Describe
var Context = ginkgo.Context
var It = ginkgo.It

// TestsFile holds the basic structure of a YAML test file
type TestsFile struct {
	Namespaces map[string]K8SObjects `yaml:"namespaces"`
	Crds       []string              `yaml:"crds"`
}

// K8SObjects are kubernetes objects nested from namespaces, we need to check
// this objects exists.
type K8SObjects struct {
	Daemonsets []string `yaml:"daemonset"`
	Services   []string `yaml:"services"`
	Secrets    []string `yaml:"secrets"`
}

// config only holds the filepath for the test file. Prob we will be adding more
// parameters here in the future (directory)?
type config struct {
	TestsFilePath string
}

// NewTests create the constructor
func NewTests(path string) (*TestsFile, error) {
	c := &config{
		TestsFilePath: path,
	}

	tf, err := parseTestFile(c)
	if err != nil {
		return nil, err
	}

	return tf, nil
}

// parseTestFile reads the test file supplied and unmarshal it within TestFile
func parseTestFile(c *config) (*TestsFile, error) {
	testsFilePath, err := ioutil.ReadFile(c.TestsFilePath)
	if err != nil {
		return nil, err
	}

	t := TestsFile{}

	err = yaml.Unmarshal(testsFilePath, &t)
	if err != nil {
		return nil, err
	}

	return &t, nil
}

func (tf *TestsFile) RunTests(t *testing.T) error {
	err := tf.namespaces(t)
	if err != nil {
		return err
	}

	err = tf.daemonsets(t)
	if err != nil {
		return err
	}

	return nil
}

// namespaces checks the namespace exists
func (tf *TestsFile) namespaces(t *testing.T) error {
	var ns []string
	for key := range tf.Namespaces {
		ns = append(ns, key)
	}

	Describe("Namespaces existence", func() {
		It(fmt.Sprintf("Namespaces [%v] should exist", strings.Join(ns[:], ",")), func() {
			for _, n := range ns {
				options := k8s.NewKubectlOptions("", "", n)
				_, err := k8s.GetNamespaceE(t, options, n)

				if err != nil {
					ginkgo.Fail(fmt.Sprintf("Namespace %s DOES NOT exist", n))
				}
			}
		})
	})

	return nil
}

// namespaces checks the namespace exists
func (tf *TestsFile) daemonsets(t *testing.T) error {
	Describe("Daemonsets existence", func() {

		for key, value := range tf.Namespaces {
			if value.Daemonsets != nil {
				spew.Dump(key, value.Daemonsets)
			}

			// spew.Dump(value)
			// It(fgmt.Sprintf("Daemonset [%v] within namespace [%v] should exist", ), func() {

		}

	})
	return nil
}

func daemonsetsE(ns string, ds string) error {
	return nil
}
