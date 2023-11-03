package integration_tests

import (
	"fmt"
	"html/template"
	"strings"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("GIVEN PRIVILEGED pod security admission", func() {
	Context("WHEN a ephemeral container is in a PRIVILEGED namespace", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
		)
		BeforeEach(func() {
			Skip("Skipping ephemeral PSA tests we don't currently have any ephemeral containers in live")
			namespace = fmt.Sprintf("%s-psa-%s", c.Prefix, strings.ToLower(random.UniqueId()))
			options = k8s.NewKubectlOptions("", "", namespace)

			tpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
				"psaMode":   "enforce",
				"psaLevel":  "privileged",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		AfterEach(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN ALLOW `spec.ephemeralContainers.securityContext.runAsNonRoot: false`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":             namespace,
				"deploymentName":        "app-" + strings.ToLower(random.UniqueId()),
				"ephemeralContainers":   true,
				"ephemeralRunAsNonRoot": false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN ALLOW `spec.ephemeralContainers.securityContext.runAsNonRoot: true` values", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":             namespace,
				"deploymentName":        "app-" + strings.ToLower(random.UniqueId()),
				"ephemeralContainers":   true,
				"ephemeralRunAsNonRoot": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN ALLOW `spec.ephemeralContainers.securityContext.allowPrivilegeEscalation: false`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			deploymentName := "app-" + strings.ToLower(random.UniqueId())
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": deploymentName,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			ephTpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                         namespace,
				"deploymentName":                    deploymentName,
				"ephemeralContainers":               true,
				"ephemeralAllowPrivilegeEscalation": false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, ephTpl)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN ALLOW `spec.ephemeralContainers.securityContext.allowPrivilegeEscalation: true`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                         namespace,
				"deploymentName":                    "app-" + strings.ToLower(random.UniqueId()),
				"ephemeralContainers":               true,
				"ephemeralAllowPrivilegeEscalation": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN ALLOW `spec.ephemeralcontainers.securityContext.capabilities.drop: ['ALL']`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                 namespace,
				"deploymentName":            "app-" + strings.ToLower(random.UniqueId()),
				"ephemeralContainers":       true,
				"ephemeralCapabilitiesDrop": "[\"ALL\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN ALLOW `spec.ephemeralcontainers.securityContext.capabilities.drop: ['NET_RAW']`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                 namespace,
				"deploymentName":            "app-" + strings.ToLower(random.UniqueId()),
				"ephemeralContainers":       true,
				"ephemeralCapabilitiesDrop": "[\"NET_RAW\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN ALLOW `spec.ephemeralcontainers.securityContext.capabilities.add: ['NET_RAW']`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                namespace,
				"deploymentName":           "app-" + strings.ToLower(random.UniqueId()),
				"ephemeralContainers":      true,
				"ephemeralCapabilitiesAdd": "[\"SYS_TIME\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})
	})
})
