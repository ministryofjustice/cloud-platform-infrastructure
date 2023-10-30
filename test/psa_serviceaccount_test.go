package integration_tests

import (
	"fmt"
	"html/template"
	"os"
	"strings"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

var _ = Describe("GIVEN pod security admission", func() {
	var (
		namespace string
		options   *k8s.KubectlOptions
	)

	AfterEach(func() {
		err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
		Expect(err).NotTo(HaveOccurred())
	})

	Context("WHEN psp is NOT being bypassed", func() {
		BeforeEach(func() {
			namespace = fmt.Sprintf("%s-restricted-psa-%s", c.Prefix, strings.ToLower(random.UniqueId()))
			options = k8s.NewKubectlOptions("", "", namespace)

			tpl, err := helpers.TemplateFile("./fixtures/namespace.yaml.tmpl", "namespace.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())
		})

		It("THEN use PSP", func() {
			tpl, err := helpers.TemplateFile("./fixtures/privileged-deployment.yaml.tmpl", "privileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			replicaSet, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "replicaset", "-oyaml")
			Expect(err).NotTo(HaveOccurred())
			Expect(replicaSet).To(ContainSubstring(`forbidden: PodSecurityPolicy`))

			deploy, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "deploy")
			Expect(err).NotTo(HaveOccurred())
			Expect(deploy).To(ContainSubstring(`privileged-integration-test   0/1`))
		})
	})

	Context("WHEN psp is being bypassed", func() {
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

		It("THEN service accounts are restricted by psa", func() {
			options = k8s.NewKubectlOptions("", "", namespace)
			serviceaccountTpl, err := helpers.TemplateFile("./fixtures/serviceaccount.yaml.tmpl", "serviceaccount.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, serviceaccountTpl)
			Expect(err).NotTo(HaveOccurred())

			token, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "create", "token", namespace)
			Expect(err).NotTo(HaveOccurred())

			privTpl, err := helpers.TemplateFile("./fixtures/privileged-deployment.yaml.tmpl", "privileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			tmpfile, err := k8s.StoreConfigToTempFileE(GinkgoT(), privTpl)
			Expect(err).NotTo(HaveOccurred())

			defer os.Remove(tmpfile)

			deployOutput, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "apply", "--token="+token, "-f", tmpfile)
			Expect(err).NotTo(HaveOccurred())

			Expect(deployOutput).To(ContainSubstring(`created`))

			replicaSet, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "replicaset", "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(replicaSet).To(ContainSubstring(`violates PodSecurity "restricted:latest": runAsUser=0 (pod must not set runAsUser=0)`))
		})

		It("THEN authenticated users via kubectl are restricted by psa", func() {
			tpl, err := helpers.TemplateFile("./fixtures/privileged-deployment.yaml.tmpl", "privileged-deployment.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).NotTo(HaveOccurred())

			replicaSet, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "replicaset", "-oyaml")
			Expect(err).NotTo(HaveOccurred())

			Expect(replicaSet).To(ContainSubstring(`violates PodSecurity "restricted:latest": runAsUser=0 (pod must not set runAsUser=0)`))
		})

		It("THEN service accounts haven't got escalated privilege", func() {
			options = k8s.NewKubectlOptions("", "", namespace)
			serviceaccountTpl, err := helpers.TemplateFile("./fixtures/serviceaccount.yaml.tmpl", "serviceaccount.yaml.tmpl", template.FuncMap{
				"namespace": namespace,
			})
			Expect(err).NotTo(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, serviceaccountTpl)
			Expect(err).NotTo(HaveOccurred())

			token, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "create", "token", namespace)
			Expect(err).NotTo(HaveOccurred())

			options = k8s.NewKubectlOptions("", "", namespace)
			permission, err := k8s.RunKubectlAndGetOutputE(GinkgoT(), options, "get", "pods", "-n", "kube-system", "--token="+token)
			Expect(err).To(HaveOccurred())

			Expect(permission).To(ContainSubstring(`Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:` + namespace + ":" + namespace + `" cannot list resource "pods" in API group "" in the namespace "kube-system"`))
		})
	})
})
