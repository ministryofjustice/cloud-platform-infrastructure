variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = "list"
}

variable "aws_master_account_id" {}

variable "cloud_platform_slack_webhook" {
  description = "Slack webhook to pass it to  script to send alerts"
}
