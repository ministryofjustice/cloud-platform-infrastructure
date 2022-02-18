variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
}

variable "live1_domain" {
  default     = "live-1.et.cloud-platform.service.justice.gov.uk"
  description = "cluster domain name for live-1"
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = list(any)
}

variable "elasticsearch_hosts_maps" {
  default = {
    manager = ""
    live    = ""
  }
}

variable "elasticsearch_audit_hosts_maps" {
  default = {
    manager = ""
    live    = ""
  }
}

variable "cluster_r53_domainfilters" {
  default = {
    live-1  = ["*"]
    manager = ["manager.et.cloud-platform.service.justice.gov.uk.", "et.cloud-platform.service.justice.gov.uk."]
  }
}
