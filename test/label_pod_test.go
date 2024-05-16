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

var _ = Describe("GIVEN a pod", func() {
	var (
		namespace string
		options   *k8s.KubectlOptions
		oldLogger *logger.Logger
	)
	BeforeEach(func() {
		namespace = fmt.Sprintf("%s-label-pod-%s", c.Prefix, strings.ToLower(random.UniqueId()))
		options = k8s.NewKubectlOptions("", "", namespace)
		oldLogger = options.Logger
		options.Logger = logger.Discard
	})

	AfterEach(func() {
		err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
		Expect(err).NotTo(HaveOccurred())
		defer func() { options.Logger = oldLogger }()
	})

	Context("WHEN a pod has a SINGLE github team in it's rbac", func() {
		It("THEN add an annotation with that github team", func() {
			nsTpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, nsTpl)
			Expect(err).NotTo(HaveOccurred())

			tpl, err := helpers.TemplateFile("./fixtures/unprivileged-deployment.yaml.tmpl", "unprivileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})

			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			pod, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-n", namespace, "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(pod).To(ContainSubstring(`github_teams: test-webops`))
		})

		It("THEN add an annotation even when annotations previously exist", func() {
			nsTpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, nsTpl)
			Expect(err).NotTo(HaveOccurred())

			tpl, err := helpers.TemplateFile("./fixtures/unprivileged-deployment.yaml.tmpl", "unprivileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace":              namespace,
				"preexistingAnnotations": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			pod, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-n", namespace, "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(pod).To(ContainSubstring(`github_teams: test-webops`))
		})
	})

	Context("WHEN a pod has a MULTIPLE github teams in it's rbac", func() {
		It("THEN add an annotation with multiple teams", func() {
			nsTpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace":       namespace,
				"multiGithubRbac": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, nsTpl)
			Expect(err).NotTo(HaveOccurred())

			tpl, err := helpers.TemplateFile("./fixtures/unprivileged-deployment.yaml.tmpl", "unprivileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			pod, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-n", namespace, "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(pod).To(ContainSubstring(`github_teams: test-webops_test-webops-2`))
		})
	})

	Context("WHEN a pod has a NO github teams in it's rbac", func() {
		It("THEN add an annotation with multiple teams", func() {
			nsTpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace":          namespace,
				"disableRoleBinding": true,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, nsTpl)
			Expect(err).NotTo(HaveOccurred())

			tpl, err := helpers.TemplateFile("./fixtures/unprivileged-deployment.yaml.tmpl", "unprivileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			pod, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pod", "-n", namespace, "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(pod).To(ContainSubstring(`github_teams: all-org-members`))
		})
	})
})
