package integration_tests

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
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
)

type PhraseData struct {
	Log      string `json:"log,omitempty"`
	Stream   string `json:"stream,omitempty"`
	HttpCode int    `json:"transaction.response.http_code,omitempty"`
}

type FilterData struct {
	Match PhraseData `json:"match_phrase"`
}

type MustFilterData struct {
	Must   []interface{} `json:"must"`
	Filter []FilterData  `json:"filter"`
}

type BoolData struct {
	Bool MustFilterData `json:"bool"`
}

type SearchData struct {
	Query BoolData `json:"query"`
}

func getSearchResults(values SearchData, search string, awsSigner *signer.Signer, client *http.Client) {
	type ValueKey struct {
		Value int `json:"value"`
	}

	type TotalKey struct {
		Total ValueKey `json:"total"`
	}

	type Resp struct {
		Hits TotalKey `json:"hits"`
	}

	jsonData, err := json.Marshal(values)

	Expect(err).ToNot(HaveOccurred())

	req, reqErr := http.NewRequest(http.MethodGet, search, bytes.NewBuffer(jsonData))

	Expect(reqErr).ToNot(HaveOccurred())

	req.Header.Add("Content-Type", "application/json")

	_, signErr := awsSigner.Sign(req, bytes.NewReader(jsonData), "es", "eu-west-2", time.Now())

	Expect(signErr).ToNot(HaveOccurred())

	time.Sleep(10 * time.Second) // prevent dial tcp: lookup smoketest-logs-usepwe.integrationtest.service.justice.gov.uk: no such host errors

	resp, httpErr := client.Do(req)

	Expect(httpErr).ToNot(HaveOccurred())

	body, bodyErr := io.ReadAll(resp.Body)

	Expect(bodyErr).ToNot(HaveOccurred())

	defer resp.Body.Close()

	var hits Resp

	unmarshalErr := json.Unmarshal(body, &hits)

	Expect(unmarshalErr).ToNot(HaveOccurred())

	// Check the logs for the expected message
	Expect(hits.Hits.Total.Value).To(Equal(100))
}

// Logging tests define the ability for Cloud Platform to perform aggregated logging
// on the platform. The tests are designed to be run in a Kubernetes cluster, with a logging agent installed.
var _ = Describe("logging", func() {
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

		BeforeEach(func() {
			if !(c.ClusterName == "live") {
				Skip(fmt.Sprintf("Logs don't go to opensearch for cluster: %s", c.ClusterName))
			}

			uniqueId = strings.ToLower(random.UniqueId())

			// Create a helloworld app
			namespace = fmt.Sprintf("%s-logs-%s", c.Prefix, uniqueId)
			options = k8s.NewKubectlOptions("", "", namespace)
			host := fmt.Sprintf("%s.%s", namespace, testDomain)
			err := k8s.CreateNamespaceE(GinkgoT(), options, namespace)
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

			sum := 0
			req, _ := http.NewRequest(http.MethodGet, "http://"+host+"/aphpfilethatdonotexist.php?something=../../etc", nil)

			time.Sleep(40 * time.Second) // // prevent dial tcp: lookup smoketest-logs-usepwe.integrationtest.service.justice.gov.uk: no such host errors

			for i := 0; i < 100; i++ {
				resp, doErr := getClient.Do(req)
				if doErr != nil {
					log.Panic(doErr)
				}

				defer resp.Body.Close()

				Expect(resp.Status).To(Equal("403 Forbidden"))

				sum += i
			}

			Expect(err).ToNot(HaveOccurred())
		})

		AfterEach(func() {
			err := k8s.DeleteNamespaceE(GinkgoT(), options, namespace)
			Expect(err).ToNot(HaveOccurred())
		})

		It("should be able to retrieve the log message", func() {
			awsCreds := creds.NewEnvCredentials()
			awsSigner := signer.NewSigner(awsCreds)

			emptySlice := make([]interface{}, 0)
			values := SearchData{
				Query: BoolData{
					MustFilterData{
						Must: emptySlice,
						Filter: []FilterData{
							{Match: PhraseData{
								Log: "github_team=" + uniqueId,
							}},
							{Match: PhraseData{
								Stream: "stderr",
							}},
						},
					},
				},
			}

			auditValues := SearchData{
				Query: BoolData{
					MustFilterData{
						Must: emptySlice,
						Filter: []FilterData{
							{Match: PhraseData{
								Log: "github_team=" + uniqueId,
							}},
							{Match: PhraseData{
								HttpCode: 403,
							}},
						},
					},
				},
			}

			getSearchResults(values, search, awsSigner, client)
			getSearchResults(auditValues, search, awsSigner, client)
		})
	})
})
