# AWS GuardDuty variables:

variable "aws_region" {
}

variable "aws_region-london" {
}

variable "integration_key" {
}

variable "endpoint" {
}

variable "topic_arn" {
}

variable "sns_arn" {
}

variable "aws_master_account_id" {
}

variable "aws_master_profile" {
}

variable "aws_master-london_account_id" {
}

variable "aws_master-london_profile" {
}

variable "aws_member1_account_id" {
}

variable "aws_member1_profile" {
}

variable "member1_email" {
}

variable "aws_member2_account_id" {
}

variable "aws_member2_profile" {
}

variable "member2_email" {
}

variable "aws_member3_account_id" {
}

variable "aws_member3_profile" {
}

variable "member3_email" {
}

variable "aws_member4_account_id" {
}

variable "aws_member4_profile" {
}

variable "member4_email" {
}

#variable "aws_member5_account_id" {
#}

#variable "aws_member5_profile" {
#}

#variable "member5_email" {
#}

variable "aws_member6_account_id" {
}

variable "aws_member6_profile" {
}

variable "member6_email" {
}

variable "aws_member7_account_id" {
}

variable "aws_member7_profile" {
}

variable "member7_email" {
}

variable "users" {
  type = list(string)
}

variable "bucket_prefix" {
  default = "security"
}

variable "group_name" {
  default = "guardduty-admin"
}

variable "tags" {
  default = {
    "application"            = "AWS GuardDuty"
    "business-unit"          = "HQ"
    "component"              = "none"
    "environment-name"       = "production"
    "infrastructure-support" = "Cloud Platforms platforms@digital.justice.gov.uk"
    "is-production"          = "true"
    "owner"                  = "Cloud Platforms platforms@digital.justice.gov.uk"
    "runbook"                = "none"
  }
}

