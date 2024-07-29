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
var _ = Describe("logging", Ordered, func() {
	Context("when an app generates a log message", func() {
		var (
			namespace string
			options   *k8s.KubectlOptions
			uniqueId  string
		)

		openSearchDomain := "https://search-cp-live-app-logs-jywwr7het3xzoh5t7ajar4ho3m.eu-west-2.es.amazonaws.com/"
		date := time.Now().Format("2006.01.02")
		search := openSearchDomain + c.ClusterName + "_kubernetes_cluster" + "-" + date + "/_search"
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

			setIdentifier := "integration-test-app-ing-" + namespace + "-green"

			helloVar := map[string]interface{}{
				"namespace": namespace,
				"host":      host,
				"ingress_annotations": map[string]string{
					"external-dns.alpha.kubernetes.io/aws-weight":     "\"100\"",
					"external-dns.alpha.kubernetes.io/set-identifier": setIdentifier,
				},
			}

			tpl, err := helpers.TemplateFile("./fixtures/helloworld-deployment-v1.yaml.tmpl", "helloworld-deployment-v1.yaml.tmpl", helloVar)
			Expect(err).ToNot(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			k8s.WaitUntilIngressAvailable(GinkgoT(), options, "integration-test-app-ing", 8, 20*time.Second)

			// Create a job that creates a simple log message.
			jobVar := map[string]interface{}{
				"jobName":   "logging-smoketest",
				"namespace": namespace,
			}

			tpl, err = helpers.TemplateFile("./fixtures/helloworld-job.yaml.tmpl", "helloworld-job.yaml.tmpl", jobVar)
			Expect(err).ToNot(HaveOccurred())

			err = k8s.KubectlApplyFromStringE(GinkgoT(), options, tpl)
			Expect(err).ToNot(HaveOccurred())

			// Wait for the job to complete
			err = k8s.WaitUntilJobSucceedE(GinkgoT(), options, "logging-smoketest", 10, 20*time.Second)
			Expect(err).ToNot(HaveOccurred())

			tr := &http.Transport{
				TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
			}
			getClient := &http.Client{Transport: tr}

			req, _ := http.NewRequest(http.MethodGet, "http://"+host, nil)

			time.Sleep(40 * time.Second) // // prevent dial tcp: lookup smoketest-logs-usepwe.integrationtest.service.justice.gov.uk: no such host errors

			for i := 0; i < 100; i++ {
				resp, doErr := getClient.Do(req)
				if doErr != nil {
					log.Panic(doErr)
				}

				defer resp.Body.Close()
			}

			Expect(err).ToNot(HaveOccurred())
		})

		AfterAll(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).ToNot(HaveOccurred())
		})

		Describe("check app logs have not been dropped", Ordered, func() {
			It("should be able to retrieve the log messages from opensearch", func() {
				Skip("Skipping this test whilst OpenSearch logging is temporarily disabled")
				values := helpers.SearchData{
					Query: helpers.BoolData{
						Bool: helpers.MustFilterData{
							Must: emptySlice,
							Filter: []helpers.FilterData{
								{Match: helpers.PhraseData{
									Namespace: namespace,
								}},
								{Match: helpers.PhraseData{
									Stream: "stdout",
								}},
							},
						},
					},
				}

				helpers.GetSearchResults(values, search, awsSigner, client)
			})
		})
	})
})
