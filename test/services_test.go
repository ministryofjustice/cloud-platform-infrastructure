package integration_tests

import (
	. "github.com/onsi/ginkgo"
)

// Services defined in plain text in the cluster manifest.
var _ = Describe("The services in the cluster", func() {
	// var servicesNotRunning []string

	// It("should exist as defined", func() {
	// 	services := c.GetExpectedServices()
	// 	if len(services) == 0 {
	// 		Skip("No services defined, skipping test")
	// 	}

	// 	for namespace, svc := range services {
	// 		options := k8s.NewKubectlOptions("", "", namespace)
	// 		for _, v := range svc {
	// 			_, err := k8s.GetServiceE(GinkgoT(), options, v)
	// 			if err != nil {
	// 				servicesNotRunning = append(servicesNotRunning, v)
	// 			}
	// 		}
	// 	}

	// 	if servicesNotRunning != nil {
	// 		Fail(fmt.Sprintf("The following services DO NOT exist: %v", servicesNotRunning))
	// 	}
})

// It("shouldn't be there because they're fake", func() {
// 	fakeService := "ObviouslyFake"

// 	options := k8s.NewKubectlOptions("", "", "default")
// 	_, err := k8s.GetServiceE(GinkgoT(), options, fakeService)
// 	if err.Error() == "services \"ObviouslyFake\" not found" {
// 		return
// 	}
// 	Fail(fmt.Sprintf("A service named %s shouldn't exist.", fakeService))
// })
// })
