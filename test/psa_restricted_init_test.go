package integration_tests

import (
	"fmt"
	"html/template"
	"strings"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("GIVEN RESTRICTED pod security admission", func() {
	Context("WHEN an initContainer is in a RESTRICTED namespace", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
			oldLogger *logger.Logger
		)
		BeforeEach(func() {
			namespace = fmt.Sprintf("%s-restricted-psa-%s", c.Prefix, strings.ToLower(random.UniqueId()))
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
		})

		AfterEach(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).NotTo(HaveOccurred())
			defer func() { options.Logger = oldLogger }()
		})

		It("THEN ALLOW `spec.initContainers.securityContext.runAsNonRoot: false`, mutation corrects value", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":        namespace,
				"deploymentName":   "app-" + strings.ToLower(random.UniqueId()),
				"initContainers":   true,
				"initRunAsNonRoot": false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			runNonRootDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(runNonRootDeploy).To(ContainSubstring("runAsNonRoot: true"))
		})

		It("THEN ALLOW `spec.initContainers.securityContext.runAsNonRoot: true` values", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":        namespace,
				"deploymentName":   "app-" + strings.ToLower(random.UniqueId()),
				"initContainers":   true,
				"initRunAsNonRoot": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			runNonRootDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(runNonRootDeploy).To(ContainSubstring("runAsNonRoot: true"))
		})

		It("THEN ALLOW `spec.initContainers.securityContext.allowPrivilegeEscalation: false`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                    namespace,
				"deploymentName":               "app-" + strings.ToLower(random.UniqueId()),
				"initContainers":               true,
				"initAllowPrivilegeEscalation": false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			allowPrivilegeDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(allowPrivilegeDeploy).To(ContainSubstring("allowPrivilegeEscalation: false"))
		})

		It("THEN ALLOW `spec.initContainers.securityContext.allowPrivilegeEscalation: true`, mutation corrects value", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                    namespace,
				"deploymentName":               "app-" + strings.ToLower(random.UniqueId()),
				"initContainers":               true,
				"initAllowPrivilegeEscalation": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			allowPrivilegeDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(allowPrivilegeDeploy).To(ContainSubstring("allowPrivilegeEscalation: false"))
		})

		It("THEN ALLOW `spec.initContainers.securityContext.capabilities.drop: ['ALL']`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":            namespace,
				"deploymentName":       "app-" + strings.ToLower(random.UniqueId()),
				"initContainers":       true,
				"initCapabilitiesDrop": "[\"ALL\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			capabilitiesDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(capabilitiesDeploy).To(MatchRegexp("capabilities:\n.*drop:\n.*- ALL"))
		})

		It("THEN ALLOW `securityContext.capabilities.drop: ['NET_RAW']`, mutation corrects value", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":            namespace,
				"deploymentName":       "app-" + strings.ToLower(random.UniqueId()),
				"initContainers":       true,
				"initCapabilitiesDrop": "[\"NET_RAW\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			capabilitiesDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(capabilitiesDeploy).To(MatchRegexp("capabilities:\n.*drop:\n.*- ALL"))
		})

		It("THEN DENY `spec.initContainers.securityContext.capabilities.add: ['NET_RAW']`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":           namespace,
				"deploymentName":      "app-" + strings.ToLower(random.UniqueId()),
				"initContainers":      true,
				"initCapabilitiesAdd": "[\"NET_RAW\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).To(HaveOccurred())

			Expect(err.Error()).To(MatchRegexp("is forbidden: violates PodSecurity \"restricted:latest\": unrestricted capabilities .container \"init-test-app-[a-z0-9]{6}\" must not include \"NET_RAW\" in securityContext.capabilities.add"))
		})

		It("THEN DENY `spec.initContainers.securityContext.runAsUser: 0`", func() {
			Skip("This case is not restricted by psa, skip until we implement the equivalent constraint in gatekeeper")
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"initContainers": true,
				"initRunAsUser":  0,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).To(HaveOccurred())

			replicaSet, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "replicaset", "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(replicaSet).To(ContainSubstring(`violates PodSecurity "restricted:latest": runAsUser=0 (pod must not set runAsUser=0)`))

			deploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "deploy")
			Expect(err).NotTo(HaveOccurred())

			Expect(deploy).To(ContainSubstring(`privileged-integration-test   0/1`))
		})

		It("THEN ALLOW `spec.initContainers.securityContext.runAsUser: 1001`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"initContainers": true,
				"initRunAsUser":  1001,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			runAsUserDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(runAsUserDeploy).To(ContainSubstring("runAsUser: 1001"))
		})
	})
})
