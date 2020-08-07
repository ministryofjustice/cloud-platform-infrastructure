variable "slack_config_cloudwatch_lp" {
  description = "Add Slack webhook API URL for integration with slack."
}

variable "aws_region" {
  description = "Region where components and resources are going to be deployed"
  default     = "eu-west-2"
}
