package config

// NginxIngressController holds the config for nginx ingress controller component
type NginxIngressController struct {
	NamespacePrefix string `yaml:"namespacePrefix"`
}
