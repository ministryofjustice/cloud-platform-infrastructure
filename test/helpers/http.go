package helpers

import "github.com/go-resty/resty/v2"

// HttpStatusCode return the HTTP code for an endpoint
func HttpStatusCode(u string) (int, error) {
	client := resty.New()
	resp, err := client.R().EnableTrace().Get(u)
	if err != nil {
		return 0, err
	}

	return resp.StatusCode(), nil
}
