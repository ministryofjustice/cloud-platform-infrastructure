package integration_tests

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

// Mock event structure similar to the one in Node.js
type Event struct {
	Connection struct {
		Name string `json:"name"`
	} `json:"connection"`
	User struct {
		Nickname     string   `json:"nickname"`
		UserMetadata Metadata `json:"user_metadata"`
	} `json:"user"`
	Secrets struct {
		AwsSamlProvider string `json:"AWS_SAML_PROVIDER_NAME"`
		AwsAccountID    string `json:"AWS_ACCOUNT_ID"`
		FilterApiKey    string `json:"FILTER_API_KEY"`
	} `json:"secrets"`
}

// Metadata struct for GitHub teams
type Metadata struct {
	GhTeams []string `json:"gh_teams"`
}

// Response from the mock API
type FilterResponse struct {
	FilteredTeams string `json:"filtered_teams"`
}

var _ = Describe("PostLogin Function", func() {
	It("should process GitHub teams and call the filter API", func() {
		req, _ := http.NewRequest("POST", "https://github-teams-filter.apps.live.cloud-platform.service.justice.gov.uk/filter-teams", bytes.NewBuffer([]byte(`{"teams": ":badteam:webops:test1:test2:worstteam:dps-tech"}`)))
		req.Header.Set("Content-Type", "application/json")
		apiKey := os.Getenv("TEAMS_FILTER_API_KEY")

		Expect(apiKey).To(Not(BeEmpty()))

		req.Header.Set("X-API-Key", apiKey)

		client := &http.Client{}
		resp, err := client.Do(req)

		Expect(err).To(BeNil())
		Expect(resp.StatusCode).To(Equal(http.StatusOK))

		defer resp.Body.Close()
		body, _ := io.ReadAll(resp.Body)
		Expect(err).To(BeNil())

		var result FilterResponse
		json.Unmarshal(body, &result)
		Expect(err).To(BeNil())

		fmt.Println("Processed GitHub teams:", result.FilteredTeams)
		Expect(result.FilteredTeams).To(Equal(":webops:dps-tech:"))

	})
})
