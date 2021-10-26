package config

import (
	"fmt"
	"strings"

	"github.com/gruntwork-io/terratest/modules/random"
)

// ExternalDNS holds the config for externalDNS component
type ExternalDNS struct {
	NamespacePrefix string `yaml:"namespacePrefix"`
	HostedZoneId    string `yaml:"hostedZoneId"`
	Domain          string `yaml:"domain"`
}

// GetNamespaceName returns random namespace name, it considers (if set) the prefix
// specified in the configuration
func (e *ExternalDNS) GetNamespaceName() string {
	if e.NamespacePrefix != "" {
		return fmt.Sprintf("%s%s", e.NamespacePrefix, strings.ToLower(random.UniqueId()))
	}

	return fmt.Sprintf("external-dns-test-%s", strings.ToLower(random.UniqueId()))
}
