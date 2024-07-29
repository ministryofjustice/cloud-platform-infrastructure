package integration_tests

import (
	"crypto/tls"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	creds "github.com/aws/aws-sdk-go/aws/credentials"
	signer "github.com/aws/aws-sdk-go/aws/signer/v4"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/ministryofjustice/cloud-platform-infrastructure/test/helpers"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// Logging tests define the ability for Cloud Platform to perform aggregated logging
// on the platform. The tests are designed to be run in a Kubernetes cluster, with a logging agent installed.
var _ = Describe("logging", Ordered, Serial, func() {
	Context("when an app generates a log message", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
			uniqueId  string
		)

		openSearchDomain := "https://search-cp-live-modsec-audit-nuhzlrjwxrmdd6op3mvj2k5mye.eu-west-2.es.amazonaws.com/"
		date := time.Now().Format("2006.01.02")
		search := openSearchDomain + c.ClusterName + "_k8s_modsec_ingress" + "-" + date + "/_search"
		client := &http.Client{}
		awsCreds := creds.NewEnvCredentials()
		awsSigner := signer.NewSigner(awsCreds)

		emptySlice := make([]interface{}, 0)

		BeforeAll(func() {
			if !(c.ClusterName == "live") {
				Skip(fmt.Sprintf("Logs don't go to opensearch for cluster: %s", c.ClusterName))
			}

			uniqueId = strings.ToLower(random.UniqueId())

			// Create a helloworld app
			namespace = fmt.Sprintf("%s-logs-%s", c.Prefix, uniqueId)
			options = k8s.NewKubectlOptions("", "", namespace)
			host := fmt.Sprintf("%s.%s", namespace, testDomain)

			nsObject := metav1.ObjectMeta{
				Name: namespace,
				Labels: map[string]string{
					"pod-security.kubernetes.io/enforce": "restricted",
				},
			}

			err := k8s.CreateNamespaceWithMetadataE(GinkgoT(), options, nsObject)
			Expect(err).ToNot(HaveOccurred())
			class := "modsec"

			setIdentifier := "integration-test-app-ing-" + namespace + "-green"

			modsecStr := []byte(`|
             SecRuleEngine On
             SecDefaultAction "phase:2,pass,log,tag:github_team=%s"`)

			formattedModsecStr := fmt.Sprintf(string(modsecStr), uniqueId)

			helloVar := map[string]interface{}{
				"namespace": namespace,
				"host":      host,
				"class":     class,
				"ingress_annotations": map[string]string{
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
					"nginx.ingress.kubernetes.io/enable-modsecurity":  "\"true\"",
					"nginx.ingress.kubernetes.io/modsecurity-snippet": formattedModsecStr,
				},
			}

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment-v1.yaml.tmpl", "helloworld-deployment-v1.yaml.tmpl", helloVar)
			Expect(err).ToNot(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			k8s.WaitUntilIngressAvailable(GinkgoT(), options, "integration-test-app-ing", 8, 20*time.Second)

			tr := &http.Transport{
				TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
			}
			getClient := &http.Client{Transport: tr}

			req, _ := http.NewRequest(http.MethodGet, "http://"+host+"/aphpfilethatdonotexist.php?something=../../etc", nil)

			time.Sleep(40 * time.Second) // // prevent dial tcp: lookup smoketest-logs-usepwe.integrationtest.service.justice.gov.uk: no such host errors

			for i := 0; i < 100; i++ {
				resp, doErr := getClient.Do(req)
				if doErr != nil {
					log.Panic(doErr)
				}

				defer resp.Body.Close()

				Expect(resp.Status).To(Equal("403 Forbidden"))
			}

			Expect(err).ToNot(HaveOccurred())
		})

		AfterAll(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).ToNot(HaveOccurred())
		})

		Describe("check modsec logs have not been dropped", Ordered, func() {
			It("should be able to retrieve the log messages from modsec opensearch", func() {
				values := helpers.SearchData{
					Query: helpers.BoolData{
						Bool: helpers.MustFilterData{
							Must: emptySlice,
							Filter: []helpers.FilterData{
								{Match: helpers.PhraseData{
									Log: "github_team=" + uniqueId,
								}},
								{Match: helpers.PhraseData{
									Stream: "stderr",
								}},
							},
						},
					},
				}

				helpers.GetSearchResults(values, search, awsSigner, client)
			})

			It("should be able to retrieve the audit log messages from modsec opensearch", func() {
				auditValues := helpers.SearchData{
					Query: helpers.BoolData{
						Bool: helpers.MustFilterData{
							Must: emptySlice,
							Filter: []helpers.FilterData{
								{Match: helpers.PhraseData{
									Log: "github_team=" + uniqueId,
								}},
								{Match: helpers.PhraseData{
									HttpCode: 403,
								}},
							},
						},
					},
				}

				helpers.GetSearchResults(auditValues, search, awsSigner, client)
			})
		})
	})
})
