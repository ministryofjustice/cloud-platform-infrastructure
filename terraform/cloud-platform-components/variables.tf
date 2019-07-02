variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = "list"
}

variable "DUMMY_ELASTICSEARCH" {
  description = "In case the cluster doesn't need to connect to an actual ES cluster, enable this var"
  default     = 0
}
