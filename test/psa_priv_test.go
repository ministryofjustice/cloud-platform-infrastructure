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

var _ = Describe("GIVEN PRIVILEGED pod security admission", func() {
	Context("WHEN a container is in a PRIVILEGED namespace", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
			oldLogger *logger.Logger
		)
		BeforeEach(func() {
			namespace = fmt.Sprintf("%s-psa-%s", c.Prefix, strings.ToLower(random.UniqueId()))
			options = k8s.NewKubectlOptions("", "", namespace)
			oldLogger = options.Logger
			options.Logger = logger.Discard

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
			defer func() { options.Logger = oldLogger }()
		})

		It("THEN have a namespace with the `privileged` psa label", func() {
			ns, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "ns", namespace, "-oyaml")
			if err != nil {
				Fail(err.Error())
			}

			Expect(ns).To(ContainSubstring(`pod-security.kubernetes.io/enforce: privileged`))
		})

		It("THEN ALLOW a container with restricted (unprivileged) values to be deployed", func() {
			tpl, err := helpers.TemplateFile("./fixtures/unprivileged-deployment.yaml.tmpl", "unprivileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN ALLOW `spec.containers.securityContext.runAsNonRoot: false`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"runAsNonRoot":   false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			runNonRootDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(runNonRootDeploy).To(ContainSubstring("runAsNonRoot: false"))
		})

		It("THEN ALLOW `spec.containers.securityContext.runAsNonRoot: true`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"runAsNonRoot":   true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			runNonRootDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(runNonRootDeploy).To(ContainSubstring("runAsNonRoot: true"))
		})

		It("THEN ALLOW `spec.containers.securityContext.allowPrivilegeEscalation: false`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                namespace,
				"deploymentName":           "app-" + strings.ToLower(random.UniqueId()),
				"allowPrivilegeEscalation": false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			allowPrivilegeDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(allowPrivilegeDeploy).To(ContainSubstring("allowPrivilegeEscalation: false"))
		})

		It("THEN ALLOW `spec.containers.securityContext.allowPrivilegeEscalation: true`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                namespace,
				"deploymentName":           "app-" + strings.ToLower(random.UniqueId()),
				"allowPrivilegeEscalation": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			allowPrivilegeDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(allowPrivilegeDeploy).To(ContainSubstring("allowPrivilegeEscalation: true"))
		})

		It("THEN ALLOW `spec.containers.securityContext.capabilities.drop: ['ALL']`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":        namespace,
				"deploymentName":   "app-" + strings.ToLower(random.UniqueId()),
				"capabilitiesDrop": "[\"ALL\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			capabilitiesDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(capabilitiesDeploy).To(MatchRegexp("capabilities:\n.*drop:\n.*- ALL"))
		})

		It("THEN ALLOW `spec.containers.securityContext.capabilities.drop: ['NET_RAW']`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":        namespace,
				"deploymentName":   "app-" + strings.ToLower(random.UniqueId()),
				"capabilitiesDrop": "[\"NET_RAW\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			capabilitiesDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(capabilitiesDeploy).To(MatchRegexp("capabilities:\n.*drop:\n.*- NET_RAW"))
		})

		It("THEN ALLOW `spec.containers.securityContext.capabilities.add: ['SYS_TIME']`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":       namespace,
				"deploymentName":  "app-" + strings.ToLower(random.UniqueId()),
				"capabilitiesAdd": "[\"SYS_TIME\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			capabilitiesDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(capabilitiesDeploy).To(MatchRegexp("capabilities:\n.*add:\n.*- SYS_TIME"))
		})

		It("THEN ALLOW `spec.securityContext.fsGroup: 1`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"fsGroup":        1,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			fsGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(fsGroupDeploy).To(ContainSubstring("fsGroup: 1"))
		})

		It("THEN ALLOW `spec.securityContext.fsGroup: 2`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"fsGroup":        2,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			fsGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(fsGroupDeploy).To(ContainSubstring("fsGroup: 2"))
		})

		It("THEN ALLOW `spec.securityContext.fsGroup: 0`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"fsGroup":        0,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			fsGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(fsGroupDeploy).To(ContainSubstring("fsGroup: 0"))
		})

		It("THEN ALLOW `spec.securityContext.supplementalGroups: 1`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":          namespace,
				"deploymentName":     "app-" + strings.ToLower(random.UniqueId()),
				"supplementalGroups": "[1]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			supplementalGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(supplementalGroupDeploy).To(MatchRegexp("supplementalGroups:\n.*- 1"))
		})

		It("THEN ALLOW `spec.securityContext.supplementalGroups: 2`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":          namespace,
				"deploymentName":     "app-" + strings.ToLower(random.UniqueId()),
				"supplementalGroups": "[2]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			supplementalGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(supplementalGroupDeploy).To(MatchRegexp("supplementalGroups:\n.*- 2"))
		})

		It("THEN ALLOW `spec.securityContext.supplementalGroups: 0`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":          namespace,
				"deploymentName":     "app-" + strings.ToLower(random.UniqueId()),
				"supplementalGroups": "[0]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			supplementalGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(supplementalGroupDeploy).To(MatchRegexp("supplementalGroups:\n.*- 0"))
		})

		It("THEN ALLOW `spec.securityContext.seccompProfile.type: RuntimeDefault`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"seccompProfile": "RuntimeDefault",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			seccompDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(seccompDeploy).To(ContainSubstring("type: RuntimeDefault"))
		})

		It("THEN ALLOW `spec.securityContext.seccompProfile.type: Unconfined`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"seccompProfile": "Unconfined",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			seccompDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(seccompDeploy).To(ContainSubstring("type: Unconfined"))
		})

		It("THEN ALLOW `spec.containers.securityContext.readOnlyRootFilesystem: true`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":              namespace,
				"deploymentName":         "app-" + strings.ToLower(random.UniqueId()),
				"readOnlyRootFilesystem": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			readOnlyDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(readOnlyDeploy).To(ContainSubstring("readOnlyRootFilesystem: true"))
		})

		It("THEN ALLOW `spec.containers.securityContext.readOnlyRootFilesystem: false`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":              namespace,
				"deploymentName":         "app-" + strings.ToLower(random.UniqueId()),
				"readOnlyRootFilesystem": false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			readOnlyDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(readOnlyDeploy).To(ContainSubstring("readOnlyRootFilesystem: false"))
		})

		It("THEN ALLOW `spec.securityContext.runAsUser: 0`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"rootRunAsUser":  0,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			runAsUserDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(runAsUserDeploy).To(ContainSubstring("runAsUser: 0"))
		})

		It("THEN ALLOW `spec.securityContext.runAsUser: 1001`", func() {
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"rootRunAsUser":  1001,
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
