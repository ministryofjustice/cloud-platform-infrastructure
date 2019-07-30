variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
}
variable "slack_config" {
  description = "Add Slack webhook API URL and channel for integration with slack."
}

variable "slack_config_apply-for-legal-aid-prod" {
  description = "Add Slack webhook API URL and channel for integration with slack."
}

variable "slack_config_apply-for-legal-aid-staging" {
  description = "Add Slack webhook API URL and channel for integration with slack."
}

variable "slack_config_apply-for-legal-aid-uat" {
  description = "Add Slack webhook API URL and channel for integration with slack."
}
variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = "list"
}
