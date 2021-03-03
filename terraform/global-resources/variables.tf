# AWS GuardDuty variables:

variable "aws_region" {
}

variable "aws_region-london" {
}

variable "integration_key" {
}

variable "endpoint" {
}

variable "aws_master_account_id" {
}

variable "aws_master_profile" {
}

variable "aws_master-london_account_id" {
}

variable "aws_master-london_profile" {
}

variable "users" {
  type = list(string)
}

variable "bucket_prefix" {
  default = "security"
}

# Elasticsearch
variable "slack_webhook_url" {
}
