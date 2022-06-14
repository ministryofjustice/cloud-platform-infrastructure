package helpers

import (
	"bytes"
	"text/template"
)

// TemplateFile returns a string with the content of a template rendered
func TemplateFile(f string, n string, m interface{}) (string, error) {
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
