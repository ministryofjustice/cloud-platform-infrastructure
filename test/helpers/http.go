package helpers

import "github.com/go-resty/resty/v2"

type PrometheusResponse struct {
	Status string `json:"status"`
	Data   struct {
		Result []struct {
			Metric map[string]string `json:"metric"`
			Value  []interface{}     `json:"value"`
		} `json:"result"`
	} `json:"data"`
}

// HttpStatusCode return the HTTP code for an endpoint
func HttpStatusCode(u string) (int, error) {
	client := resty.New()
	resp, err := client.R().EnableTrace().Get(u)
	if err != nil {
		return 0, err
	}

	return resp.StatusCode(), nil
}
