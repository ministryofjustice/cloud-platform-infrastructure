variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = list
}

variable "cloud_platform_slack_webhook" {
  description = "Slack webhook to pass it to  script to send alerts"
}

variable "cluster_r53_resource_maps" {
  default = {
    manager = ["arn:aws:route53:::hostedzone/Z1OWR28V4Q2RTU", "arn:aws:route53:::hostedzone/Z5C82RHBFD2NI"]
  }
}

variable "elasticsearch_hosts_maps" {
  default = {
    manager = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
  }
}

variable "elasticsearch_audit_hosts_maps" {
  default = {
    manager = "search-cloud-platform-audit-dq5bdnjokj4yt7qozshmifug6e.eu-west-2.es.amazonaws.com"
  }
}

variable "cluster_r53_domainfilters" {
  default = {
    live-1  = ["*"]
    manager = ["manager.cloud-platform.service.justice.gov.uk.", "cloud-platform.service.justice.gov.uk."]
  }
}
