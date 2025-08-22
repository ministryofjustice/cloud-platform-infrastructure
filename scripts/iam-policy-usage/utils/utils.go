package utils

import (
	"bytes"
	"html/template"
)

func ExecuteTemplateToString(tmpl *template.Template, name string, data interface{}) string {
	var buf bytes.Buffer
	err := tmpl.ExecuteTemplate(&buf, name, data)
	if err != nil {
		return "Template error"
	}
	return buf.String()
}
