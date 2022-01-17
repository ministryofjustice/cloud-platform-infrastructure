variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = list(any)
}

variable "aws_master_account_id" {
}

variable "cloud_platform_slack_webhook" {
  description = "Slack webhook to pass it to  script to send alerts"
}

variable "github_client_id" {
}

variable "github_client_secret" {
}

variable "github_secret_key" {
}

variable "cluster_r53_resource_maps" {
  default = {
    live-1 = ["arn:aws:route53:::hostedzone/*"]
  }
}