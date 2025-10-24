package integration_tests

import (
	"fmt"
	"html/template"
	"strings"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("NetworkPolicy", func() {
	Context("Cross-namespace connectivity", func() {
		var (
			namespace1 string
			namespace2 string
			options1   *k8s.KubectlOptions
			options2   *k8s.KubectlOptions
			oldLogger  *logger.Logger
		)

		BeforeEach(func() {
			namespace1 = fmt.Sprintf("%s-netpol-test1-%s", c.Prefix, strings.ToLower(random.UniqueId()))
			namespace2 = fmt.Sprintf("%s-netpol-test2-%s", c.Prefix, strings.ToLower(random.UniqueId()))

			options1 = k8s.NewKubectlOptions("", "", namespace1)
			options2 = k8s.NewKubectlOptions("", "", namespace2)
			oldLogger = options1.Logger
			options1.Logger = logger.Discard
			options2.Logger = logger.Discard

			tpl1, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace": namespace1,
				"psaMode":   "enforce",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options1, tpl1)
			Expect(err).NotTo(HaveOccurred())

			_, err = k8s.RunKubectlAndGetOutputE(GinkgoT(), options1, "label", "namespace", namespace1, fmt.Sprintf("name=%s", namespace1))
			Expect(err).NotTo(HaveOccurred())

			tpl2, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace": namespace2,
				"psaMode":   "enforce",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options2, tpl2)
			Expect(err).NotTo(HaveOccurred())

			_, err = k8s.RunKubectlAndGetOutputE(GinkgoT(), options2, "label", "namespace", namespace2, fmt.Sprintf("name=%s", namespace2))
			Expect(err).NotTo(HaveOccurred())

			err = deployTestPod(namespace1, options1, "test-pod-1")
			Expect(err).NotTo(HaveOccurred())

			err = deployTestPod(namespace1, options1, "test-pod-1b")
			Expect(err).NotTo(HaveOccurred())

			err = deployTestPod(namespace2, options2, "test-pod-2")
			Expect(err).NotTo(HaveOccurred())

			k8s.WaitUntilPodAvailable(GinkgoT(), options1, "test-pod-1", 10, 10*time.Second)
			k8s.WaitUntilPodAvailable(GinkgoT(), options1, "test-pod-1b", 10, 10*time.Second)
			k8s.WaitUntilPodAvailable(GinkgoT(), options2, "test-pod-2", 10, 10*time.Second)
		})

		AfterEach(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options1, namespace1)
			Expect(err).NotTo(HaveOccurred())

			err = k8s.DeleteNamespaceE(GinkgoT(), options2, namespace2)
			Expect(err).NotTo(HaveOccurred())

			defer func() {
				options1.Logger = oldLogger
				options2.Logger = oldLogger
			}()
		})

		It("WHEN no NetworkPolicy THEN ALLOW cross-namespace pod connectivity", func() {
			podIP, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options2, "get", "pod", "test-pod-2", "-o", "jsonpath={.status.podIP}")
			Expect(err).NotTo(HaveOccurred())
			Expect(podIP).NotTo(BeEmpty())

			output, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options1, "exec", "test-pod-1", "--", "nc", "-z", "-v", "-w5", podIP, "8080")
			Expect(err).NotTo(HaveOccurred())
			Expect(output).To(ContainSubstring("open"))
		})

		Context("WITH Cloud Platform default deny policy", func() {
			BeforeEach(func() {
				templateVars := map[string]interface{}{
					"name":               "default",
					"namespace":          namespace1,
					"allowSameNamespace": true,
				}

				tpl, err := helpers.TemplateFile("./fixtures/networkpolicy.yaml.tmpl", "networkpolicy.yaml.tmpl", templateVars)
				Expect(err).NotTo(HaveOccurred())

				err = k8s.KubectlApplyFromStringE(GinkgoT(), options1, tpl)
				Expect(err).NotTo(HaveOccurred())

				time.Sleep(5 * time.Second)
			})

			It("THEN DENY cross-namespace traffic", func() {
				podIP, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options1, "get", "pod", "test-pod-1", "-o", "jsonpath={.status.podIP}")
				Expect(err).NotTo(HaveOccurred())
				Expect(podIP).NotTo(BeEmpty())

				_, err = k8s.RunKubectlAndGetOutputE(GinkgoT(), options2, "exec", "test-pod-2", "--", "timeout", "5", "nc", "-z", "-v", podIP, "8080")
				Expect(err).To(HaveOccurred())
			})

			It("THEN ALLOW same-namespace traffic", func() {
				podIP, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options1, "get", "pod", "test-pod-1b", "-o", "jsonpath={.status.podIP}")
				Expect(err).NotTo(HaveOccurred())
				Expect(podIP).NotTo(BeEmpty())

				output, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options1, "exec", "test-pod-1", "--", "nc", "-z", "-v", "-w5", podIP, "8080")
				Expect(err).NotTo(HaveOccurred())
				Expect(output).To(ContainSubstring("open"))
			})

			Context("WITH cross-namespace allow policy", func() {
				BeforeEach(func() {
					templateVars := map[string]interface{}{
						"name":              "allow-cross-namespace",
						"namespace":         namespace1,
						"allowedNamespaces": []string{namespace2},
					}

					tpl, err := helpers.TemplateFile("./fixtures/networkpolicy.yaml.tmpl", "networkpolicy.yaml.tmpl", templateVars)
					Expect(err).NotTo(HaveOccurred())

					err = k8s.KubectlApplyFromStringE(GinkgoT(), options1, tpl)
					Expect(err).NotTo(HaveOccurred())

					time.Sleep(5 * time.Second)
				})

				It("THEN ALLOW traffic between namespaces", func() {
					podIP, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options1, "get", "pod", "test-pod-1", "-o", "jsonpath={.status.podIP}")
					Expect(err).NotTo(HaveOccurred())
					Expect(podIP).NotTo(BeEmpty())

					output, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options2, "exec", "test-pod-2", "--", "nc", "-z", "-v", "-w5", podIP, "8080")
					Expect(err).NotTo(HaveOccurred())
					Expect(output).To(ContainSubstring("open"))
				})
			})
		})
	})

	Context("AWS-IMDS global policy access denied", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
			oldLogger *logger.Logger
		)

		BeforeEach(func() {
			namespace = fmt.Sprintf("%s-netpol-imds-%s", c.Prefix, strings.ToLower(random.UniqueId()))
			options = k8s.NewKubectlOptions("", "", namespace)
			oldLogger = options.Logger
			options.Logger = logger.Discard

			tpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
				"psaMode":   "enforce",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			err = deployTestPod(namespace, options, "test-pod")
			Expect(err).NotTo(HaveOccurred())

			k8s.WaitUntilPodAvailable(GinkgoT(), options, "test-pod", 10, 10*time.Second)
		})

		AfterEach(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).NotTo(HaveOccurred())
			defer func() { options.Logger = oldLogger }()
		})

		It("THEN DENY access to AWS IMDS", func() {
			_, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "exec", "test-pod", "--", "timeout", "5", "nc", "-z", "-v", "169.254.169.254", "80")
			Expect(err).To(HaveOccurred())
		})
	})

	Context("AWS-IMDS access permitted namespace", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
			oldLogger *logger.Logger
		)

		BeforeEach(func() {
			// This namespace can't use random string suffix because GlobalNewNetworkPolicy doesn't support wildcard notation
			namespace = fmt.Sprintf("%s-imds-allow", c.Prefix)
			options = k8s.NewKubectlOptions("", "", namespace)
			oldLogger = options.Logger
			options.Logger = logger.Discard

			tpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
				"psaMode":   "enforce",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			err = deployTestPod(namespace, options, "test-pod")
			Expect(err).NotTo(HaveOccurred())

			k8s.WaitUntilPodAvailable(GinkgoT(), options, "test-pod", 10, 10*time.Second)
		})

		AfterEach(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).NotTo(HaveOccurred())
			defer func() { options.Logger = oldLogger }()
		})

		It("THEN ALLOW access to AWS IMDS", func() {
			output, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "exec", "test-pod", "--", "timeout", "5", "nc", "-z", "-v", "169.254.169.254", "80")
			Expect(err).NotTo(HaveOccurred())
			Expect(output).To(ContainSubstring("open"))
		})
	})

	Context("Internet access default allowed", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
			oldLogger *logger.Logger
		)

		BeforeEach(func() {
			namespace = fmt.Sprintf("%s-netpol-internet-%s", c.Prefix, strings.ToLower(random.UniqueId()))
			options = k8s.NewKubectlOptions("", "", namespace)
			oldLogger = options.Logger
			options.Logger = logger.Discard

			tpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
				"psaMode":   "enforce",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			err = deployTestPod(namespace, options, "test-pod")
			Expect(err).NotTo(HaveOccurred())

			k8s.WaitUntilPodAvailable(GinkgoT(), options, "test-pod", 10, 10*time.Second)
		})

		AfterEach(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).NotTo(HaveOccurred())
			defer func() { options.Logger = oldLogger }()
		})

		It("THEN ALLOW internet access by default", func() {
			output, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "exec", "test-pod", "--", "timeout", "10", "nc", "-z", "-v", "8.8.8.8", "53")
			Expect(err).NotTo(HaveOccurred())
			Expect(output).To(ContainSubstring("open"))
		})
	})
})

func deployTestPod(namespace string, options *k8s.KubectlOptions, podName string) error {
	templateVars := map[string]interface{}{
		"podName":   podName,
		"namespace": namespace,
	}

	tpl, err := helpers.TemplateFile("./fixtures/networkpolicy-test-pod.yaml.tmpl", "networkpolicy-test-pod.yaml.tmpl", templateVars)
	if err != nil {
		return fmt.Errorf("failed to create test pod template: %s", err)
	}

	return k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
}
