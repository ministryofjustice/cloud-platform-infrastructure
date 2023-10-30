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

var _ = Describe("GIVEN RESTRICTED pod security admission", func() {
	Context("WHEN a pod is in a RESTRICTED namespace", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
		)
		BeforeEach(func() {
			namespace = fmt.Sprintf("%s-restricted-psa-%s", c.Prefix, strings.ToLower(random.UniqueId()))
			options = k8s.NewKubectlOptions("", "", namespace)

			tpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace":         namespace,
				"psaMode":           "enforce",
				"bypassPspRoleName": "psp:0-super-privileged",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		AfterEach(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN have a namespace with the `restricted` psa label", func() {
			options := k8s.NewKubectlOptions("", "", namespace)

			ns, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "ns", "-n", namespace, "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(ns).To(ContainSubstring(`pod-security.kubernetes.io/enforce: restricted`))
		})

		It("THEN DENY a deployment with the priviliged values", func() {
			tpl, err := helpers.TemplateFile("./fixtures/privileged-deployment.yaml.tmpl", "privileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			replicaSet, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "replicaset", "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(replicaSet).To(ContainSubstring(`violates PodSecurity "restricted:latest": runAsUser=0 (pod must not set runAsUser=0)`))

			deploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "deploy")
			Expect(err).NotTo(HaveOccurred())

			Expect(deploy).To(ContainSubstring(`privileged-integration-test   0/1`))
		})

		It("THEN ALLOW a pod with the restricted values to be deployed", func() {
			tpl, err := helpers.TemplateFile("./fixtures/unprivileged-deployment.yaml.tmpl", "unprivileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN ALLOW `containers.spec.securityContext.runAsNonRoot: false`, mutation corrects value", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"runAsNonRoot":   false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			runNonRootDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(runNonRootDeploy).To(ContainSubstring("runAsNonRoot: true"))
		})

		It("THEN ALLOW `containers.spec.securityContext.runAsNonRoot: true`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"runAsNonRoot":   true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			runNonRootDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(runNonRootDeploy).To(ContainSubstring("runAsNonRoot: true"))
		})

		It("THEN DENY `spec.containers.securityContext.runAsUser: 0`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"rootRunAsUser":  0,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).To(HaveOccurred())

			Expect(err.Error()).To(ContainSubstring("violates PodSecurity \"restricted:latest\": runAsUser=0 (pod must not set runAsUser=0)"))
		})

		It("THEN ALLOW `spec.containers.securityContext.runAsUser: 1001`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"rootRunAsUser":  1001,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			runAsUserDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(runAsUserDeploy).To(ContainSubstring("runAsUser: 1001"))
		})

		It("THEN ALLOW `spec.containers.securityContext.allowPrivilegeEscalation: false`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                namespace,
				"deploymentName":           "app-" + strings.ToLower(random.UniqueId()),
				"allowPrivilegeEscalation": false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			allowPrivilegeDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(allowPrivilegeDeploy).To(ContainSubstring("allowPrivilegeEscalation: false"))
		})

		It("THEN ALLOW `spec.containers.securityContext.allowPrivilegeEscalation: true`, mutation corrects value", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":                namespace,
				"deploymentName":           "app-" + strings.ToLower(random.UniqueId()),
				"allowPrivilegeEscalation": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			allowPrivilegeDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(allowPrivilegeDeploy).To(ContainSubstring("allowPrivilegeEscalation: false"))
		})

		It("THEN HAVE the 'seccomp.security.alpha.kubernetes.io/pod' annotation", func() {
			tpl, err := helpers.TemplateFile("./fixtures/unprivileged-deployment.yaml.tmpl", "unprivileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			options := k8s.NewKubectlOptions("", "", namespace)

			pod, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-l", "app=unprivileged-integration-test", "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(pod).To(ContainSubstring(`seccomp.security.alpha.kubernetes.io/pod`))
		})

		It("THEN ALLOW `containers.securityContext.capabilities.drop: ['ALL']`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":        namespace,
				"deploymentName":   "app-" + strings.ToLower(random.UniqueId()),
				"capabilitiesDrop": "[\"ALL\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			capabilitiesDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(capabilitiesDeploy).To(MatchRegexp("capabilities:\n.*drop:\n.*- ALL"))
		})

		It("THEN ALLOW `containers.securityContext.capabilities.drop: ['NET_RAW']`, mutation corrects value", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":        namespace,
				"deploymentName":   "app-" + strings.ToLower(random.UniqueId()),
				"capabilitiesDrop": "[\"NET_RAW\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			capabilitiesDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(capabilitiesDeploy).To(MatchRegexp("capabilities:\n.*drop:\n.*- ALL"))
		})

		It("THEN ALLOW `spec.securityContext.fsGroup: 1`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"fsGroup":        1,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			fsGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(fsGroupDeploy).To(ContainSubstring("fsGroup: 1"))
		})

		It("THEN ALLOW `spec.securityContext.fsGroup: 2`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"fsGroup":        2,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			fsGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(fsGroupDeploy).To(ContainSubstring("fsGroup: 2"))
		})

		It("THEN DENY `spec.securityContext.fsGroup: 0`", func() {
			Skip("This case is not restricted by psa, skip until we implement the equivalent constraint in gatekeeper")
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"fsGroup":        0,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			replicaSet, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "replicaset", "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(replicaSet).To(ContainSubstring(`violates PodSecurity "restricted:latest": runAsUser=0 (pod must not set runAsUser=0)`))

			deploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "deploy")
			Expect(err).NotTo(HaveOccurred())

			Expect(deploy).To(ContainSubstring(`privileged-integration-test   0/1`))
		})

		It("THEN ALLOW `spec.securityContext.supplementalGroups: 1`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":          namespace,
				"deploymentName":     "app-" + strings.ToLower(random.UniqueId()),
				"supplementalGroups": "[1]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			supplementalGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(supplementalGroupDeploy).To(MatchRegexp("supplementalGroups:\n.*- 1"))
		})

		It("THEN ALLOW `spec.securityContext.supplementalGroups: 2`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":          namespace,
				"deploymentName":     "app-" + strings.ToLower(random.UniqueId()),
				"supplementalGroups": "[2]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			supplementalGroupDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(supplementalGroupDeploy).To(MatchRegexp("supplementalGroups:\n.*- 2"))
		})

		It("THEN DENY `spec.securityContext.supplementalGroups: 0`", func() {
			Skip("This case is not restricted by psa, skip until we implement the equivalent constraint in gatekeeper")
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":          namespace,
				"deploymentName":     "app-" + strings.ToLower(random.UniqueId()),
				"supplementalGroups": "[0]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			replicaSet, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "replicaset", "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(replicaSet).To(ContainSubstring(`violates PodSecurity "restricted:latest": runAsUser=0 (pod must not set runAsUser=0)`))

			deploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "deploy")
			Expect(err).NotTo(HaveOccurred())

			Expect(deploy).To(ContainSubstring(`privileged-integration-test   0/1`))
		})

		It("THEN ALLOW `spec.securityContext.seccompProfile.type: RuntimeDefault`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"seccompProfile": "RuntimeDefault",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			seccompDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(seccompDeploy).To(ContainSubstring("type: RuntimeDefault"))
		})

		It("THEN DENY `spec.securityContext.seccompProfile.type: Unconfined`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":      namespace,
				"deploymentName": "app-" + strings.ToLower(random.UniqueId()),
				"seccompProfile": "Unconfined",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).To(HaveOccurred())

			Expect(err.Error()).To(ContainSubstring(`is forbidden: violates PodSecurity "restricted:latest": seccompProfile (pod must not set securityContext.seccompProfile.type to "Unconfined")`))
		})

		It("THEN ALLOW `spec.containers.securityContext.readOnlyRootFilesystem: true`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":              namespace,
				"deploymentName":         "app-" + strings.ToLower(random.UniqueId()),
				"readOnlyRootFilesystem": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			readOnlyDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(readOnlyDeploy).To(ContainSubstring("readOnlyRootFilesystem: true"))
		})

		It("THEN ALLOW `spec.containers.securityContext.readOnlyRootFilesystem: false`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":              namespace,
				"deploymentName":         "app-" + strings.ToLower(random.UniqueId()),
				"readOnlyRootFilesystem": false,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			readOnlyDeploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-oyaml")
			Expect(readOnlyDeploy).To(ContainSubstring("readOnlyRootFilesystem: false"))
		})

		It("THEN DENY `containers.securityContext.capabilities.add: ['NET_RAW']`", func() {
			options := k8s.NewKubectlOptions("", "", namespace)
			tpl, err := helpers.TemplateFile("./fixtures/dynamic-deploy.yaml.tmpl", "dynamic-deploy.yaml.tmpl", template.FuncMap{
				"namespace":       namespace,
				"deploymentName":  "app-" + strings.ToLower(random.UniqueId()),
				"capabilitiesAdd": "[\"NET_RAW\"]",
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).To(HaveOccurred())

			Expect(err.Error()).To(MatchRegexp("is forbidden: violates PodSecurity \"restricted:latest\": unrestricted capabilities .container \"app-[a-z0-9]{6}\" must not include \"NET_RAW\" in securityContext.capabilities.add"))
		})
	})
})
