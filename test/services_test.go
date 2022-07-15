package integration_tests

import (
	"fmt"

	"github.com/gruntwork-io/terratest/modules/k8s"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Services defined in plain text in the cluster manifest.
var _ = Describe("Services", func() {
	Context("when checking if the expected services exist", func() {
		It("should equal actual services in a cluster", func() {
			// Populate the expected services in the cluster
			c.ExpectedServices()

			options := k8s.NewKubectlOptions("", "", "")
			// Get the services in the clus
			services, err := k8s.ListServicesE(GinkgoT(), options, metav1.ListOptions{})
			if err != nil {
				Fail(fmt.Sprintf("Failed to get services: %s", err))
			}

			// Put the service name into a slice
			var serviceNames []string
			for _, service := range services {
				serviceNames = append(serviceNames, service.Name)
			}

			// Compare the expected services with the services in the cluster
			for _, expectedService := range c.Services {
				Expect(serviceNames).To(ContainElement(expectedService))
			}
		})
	})
})
