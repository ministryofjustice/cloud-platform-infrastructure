variable "slack_config_cloudwatch_lp" {
  description = "Add Slack webhook API URL for integration with slack."
  type        = string
}

variable "aws_region" {
  description = "Region where components and resources are going to be deployed"
  default     = "eu-west-2"
  type        = string
}

variable "kubeconfig_clusters" {
  description = "Cluster(s) credentials used by concourse pipelines to run terraform"
  type        = any
}
