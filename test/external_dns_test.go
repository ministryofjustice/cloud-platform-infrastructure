package integration_tests

import (
	"fmt"
	"html/template"
	"os"
	"strings"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// External DNS tests the external-dns function in a cluster can create
// and destroy route53 entries. It uses the test domain to register.
var _ = Describe("external-dns", Serial, func() {
	var (
		namespaceName, domain string
		options               *k8s.KubectlOptions
	)

	// You must have your AWS credentials set up in your environment before you run these tests
	BeforeEach(func() {
		if os.Getenv("AWS_PROFILE") == "" && os.Getenv("AWS_ACCESS_KEY_ID") == "" {
			Skip("AWS environment variable not defined. Skipping test.")
		}

		namespaceName = fmt.Sprintf("%s-extdns-%s", c.Prefix, strings.ToLower(random.UniqueId()))
		options = k8s.NewKubectlOptions("", "", namespaceName)
		domain = fmt.Sprintf("%s.%s", namespaceName, testDomain)

		nsObject := metav1.ObjectMeta{
			Name: namespaceName,
			Labels: map[string]string{
				"pod-security.kubernetes.io/enforce": "restricted",
			},
		}

		err := k8s.CreateNamespaceWithMetadataE(GinkgoT(), options, nsObject)
		Expect(err).ToNot(HaveOccurred())

		tpl, err := helpers.TemplateFile("./fixtures/external-dns-ingress.yaml.tmpl", "external-dns-ingress.yaml.tmpl", template.FuncMap{
			"domain":    domain,
			"namespace": namespaceName,
		})
		Expect(err).NotTo(HaveOccurred())

		k8s.KubectlApplyFromString(GinkgoT(), options, tpl)
		k8s.WaitUntilIngressAvailable(GinkgoT(), options, "e2e-tests-externaldns", 6, 20*time.Second)
	})

	AfterEach(func() {
		defer k8s.DeleteNamespace(GinkgoT(), options, namespaceName)
	})

	FContext("when creating and then deleting an ingress resource", func() {
		It("should create and then delete the A record", func() {
			GinkgoWriter.Printf("\nWaiting for A record to be created\n")
			Eventually(func() bool {
				aExists, err := helpers.RecordSets(domain, hostedZoneId, "A")
				Expect(err).NotTo(HaveOccurred())

				txtExists, err := helpers.RecordSets("_external_dns.cname."+domain, hostedZoneId, "TXT")
				Expect(err).NotTo(HaveOccurred())

				return aExists && txtExists
			}, "10m", "30s").Should(BeTrue())

			GinkgoWriter.Printf("\nDeleting ingress resource %s\n", namespaceName)
			err := k8s.RunKubectlE(GinkgoT(), options, "delete", "ingress", "e2e-tests-externaldns")
			Expect(err).NotTo(HaveOccurred())

			GinkgoWriter.Printf("\nWaiting for Route 53 records to be created\n")
			Eventually(func() bool {
				aExists, err := helpers.RecordSets(domain, hostedZoneId, "A")
				Expect(err).NotTo(HaveOccurred())

				txtExists, err := helpers.RecordSets("_external_dns.cname."+domain, hostedZoneId, "TXT")
				Expect(err).NotTo(HaveOccurred())

				return !aExists && !txtExists
			}, "10m", "30s").Should(BeTrue())
		})
	})
})
