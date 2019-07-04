variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = "list"
}

variable "elasticsearch_enabled" {
  description = "if false, fluentd won't try to connect to the existing ES cluster"
  default     = false
}
