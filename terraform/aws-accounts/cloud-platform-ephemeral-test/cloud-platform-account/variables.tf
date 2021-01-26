variable "slack_config_cloudwatch_lp" {
  description = "Add Slack webhook API URL for integration with slack."
}

variable "aws_region" {
  description = "The AWS Account region name"
  type        = string
  default     = "eu-west-2"
}

variable "aws_account_name" {
  description = "The AWS Account name, it is used for naming in multiple resources"
  type        = string
  default     = "cloud-platform-ephemeral-test"
}

