variable "slack_config_cloudwatch_lp" {
  description = "Add Slack webhook API URL for integration with slack."
  type        = string
}

variable "aws_region" {
  description = "The AWS Account region name"
  type        = string
  default     = "eu-west-2"
}
