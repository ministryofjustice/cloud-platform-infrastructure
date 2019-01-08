variable "aws_master_account_id" {}
variable "aws_master_profile" {}
variable "aws_member_account_id" {}
variable "aws_member_profile" {}
variable "aws_region" {}
variable "integration_key" {}
variable "endpoint" {}
variable "topic_arn" {}
variable "member_email" {}

variable "users" {
  type = "list"
}

variable "bucket_prefix" {
  default = "security"
}

variable "guardduty_assets" {
  default = "guardduty"
}

variable "group_name" {
  default = "guardduty-admin"
}

variable "tags" {
  default = {
    "owner"   = "moj-platform"
    "project" = "cp-guardduty"
    "client"  = "Internal"
  }
}
