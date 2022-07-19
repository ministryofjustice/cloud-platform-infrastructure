package integration_tests

import (
	"net/http"
	"strings"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("Starterpack", func() {
	host := "helloworld-app-starter-pack-0.apps." + c.ClusterName + ".cloud-platform.service.justice.gov.uk"
	It("should respond OK to a GET request", func() {
		if strings.Contains(strings.ToLower(c.ClusterName), "manager") {
			Skip("The Manager cluster does not have a Starterpack app")
		}

		resp, err := http.Get("https://" + host)
		if err != nil {
			Fail(err.Error())
		}
		defer resp.Body.Close()

		Expect(resp.StatusCode).To(Equal(200))
	})
})
