package helpers

import (
	"bytes"
	"fmt"
	"net"
	"text/template"

	"github.com/go-resty/resty/v2"
)

// HttpStatusCode return the HTTP code for an endpoint
func HttpStatusCode(u string) (int, error) {
	client := resty.New()
	resp, err := client.R().EnableTrace().Get(u)
	if err != nil {
		return 0, err
	}

	return resp.StatusCode(), nil
}

// DNSLookUp returns error if there is not DNS entry for an endpoint, used
// with retry library from terratest
func DNSLookUp(h string) (string, error) {
	if _, err := net.LookupIP(h); err != nil {
		return "", fmt.Errorf("DNS propagation hasn't happened'%w'", err)
	}

	return "", nil
}

// TemplateFile returns a string with the content of a template rendered
func TemplateFile(f string, n string, m map[string]interface{}) (string, error) {
	var b bytes.Buffer

	t, err := template.ParseFiles(f)
	if err != nil {
		return "", err
	}

	err = t.ExecuteTemplate(&b, n, m)
	if err != nil {
		return "", err
	}

	return b.String(), nil
}
