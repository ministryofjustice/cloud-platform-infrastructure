package integration_tests

import (
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Files exist checks", func() {
	It("should exist exist the following namespaces", func() {
		if len(c.FilesExist) == 0 {
			Skip("None files defined, skipping test")
		}

		for _, f := range c.FilesExist {
			statusCode, _ := http_helper.HttpGet(GinkgoT(), f, nil)

			Ω(statusCode).Should(Equal(200))
		}
	})
})
