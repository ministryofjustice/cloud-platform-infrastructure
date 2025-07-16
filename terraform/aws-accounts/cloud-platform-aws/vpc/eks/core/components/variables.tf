variable "live1_domain" {
  default     = "live-1.cloud-platform.service.justice.gov.uk"
  description = "cluster domain name for live-1"
  type        = string
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = list(any)
}

variable "elasticsearch_hosts_maps" {
  description = "Cloud Platform ElasticSearch hosts for each Terraform workspace"

  default = {
    manager = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
    live    = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
  }

  type = object({
    manager = string
    live    = string
  })
}

variable "opensearch_app_host_map" {
  description = "Cloud Platform User application logs Opensearch host for each Terraform workspace"

  default = {
    manager = "search-cp-live-app-logs-jywwr7het3xzoh5t7ajar4ho3m.eu-west-2.es.amazonaws.com"
    live    = "search-cp-live-app-logs-jywwr7het3xzoh5t7ajar4ho3m.eu-west-2.es.amazonaws.com"
  }

  type = object({
    manager = string
    live    = string
  })
}


variable "elasticsearch_modsec_audit_hosts_maps" {
  description = "Cloud Platform ModSec audit Opensearch hosts for each Terraform workspace"

  default = {
    live = "search-cp-live-modsec-audit-nuhzlrjwxrmdd6op3mvj2k5mye.eu-west-2.es.amazonaws.com"
  }

  type = object({
    live = string
  })
}

variable "hoodaw_irsa_enabled" {
  type        = bool
  default     = true
  description = "Enable IRSA for the hoodaw service account"
}
