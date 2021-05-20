package main

import (
	"log"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/ministryofjustice/tiny-k8s-tester/pkg/tests"
)

func TestKops(t *testing.T) {
	tf, err := tests.NewTests("./simple-e2e.yaml")
	if err != nil {
		log.Fatal(err)
	}

	tf.RunTests(t)
}

func TestK8S(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Tiny K8S tester")
}
