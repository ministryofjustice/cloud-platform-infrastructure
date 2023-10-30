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
	Context("WHEN an initContainer is in a RESTRICTED namespace", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
		)
		BeforeEach(func() {
			Skip("Skipping ephemeral PSA tests we don't currently have any ephemeral containers in live")
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

		It("THEN ALLOW `ephemeralContainers.spec.securityContext.runAsNonRoot: false`", func() {})

		It("THEN DENY `ephemeralContainers.spec.securityContext.runAsNonRoot: true` values", func() {})

		It("THEN ALLOW `spec.ephemeralContainers.securityContext.allowPrivilegeEscalation: false`", func() {})

		It("THEN DENY `spec.ephemeralContainers.securityContext.allowPrivilegeEscalation: true`", func() {})

		It("THEN ALLOW `ephemeralcontainers.securityContext.capabilities.drop: ['ALL']`", func() {})

		It("THEN DENY `ephemeralcontainers.securityContext.capabilities.drop: ['NET_RAW']`", func() {})

		It("THEN DENY `ephemeralcontainers.securityContext.capabilities.add: ['NET_RAW']`", func() {})
	})
})
