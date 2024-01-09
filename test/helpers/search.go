package helpers

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"time"

	signer "github.com/aws/aws-sdk-go/aws/signer/v4"
	. "github.com/onsi/gomega"
)

type PhraseData struct {
	Log       string `json:"log,omitempty"`
	Stream    string `json:"stream,omitempty"`
	HttpCode  int    `json:"transaction.response.http_code,omitempty"`
	Namespace string `json:"kubernetes.namespace_name,omitempty"`
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

func GetSearchResults(values SearchData, search string, awsSigner *signer.Signer, client *http.Client) {
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

	time.Sleep(10 * time.Second) // prevent dial tcp: lookup smoketest-logs-usepwe.integrationtest.service.justice.gov.uk: no such host errors and wait for logs

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
