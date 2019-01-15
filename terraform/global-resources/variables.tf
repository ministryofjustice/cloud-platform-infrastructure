variable "project_name" {
  default = "moj-cp-k8s-investigation"
}

variable "aws_federation_saml_x509_cert" {}
variable "aws_federation_saml_idp_domain" {}
variable "aws_federation_saml_login_url" {}
variable "aws_federation_saml_logout_url" {}

# AWS GuardDuty variables:

variable "aws_region" {}
variable "integration_key" {}
variable "endpoint" {}
variable "topic_arn" {}

variable "aws_master_account_id" {}
variable "aws_master_profile" {}

variable "aws_member_account_id" {}
variable "aws_member_profile" {}
variable "member_email" {}

variable "aws_member1_account_id" {}
variable "aws_member1_profile" {}
variable "member1_email" {}

variable "aws_member2_account_id" {}
variable "aws_member2_profile" {}
variable "member2_email" {}

variable "aws_member3_account_id" {}
variable "aws_member3_profile" {}
variable "member3_email" {}

variable "aws_member4_account_id" {}
variable "aws_member4_profile" {}
variable "member4_email" {}

variable "aws_member5_account_id" {}
variable "aws_member5_profile" {}
variable "member5_email" {}

variable "aws_member6_account_id" {}
variable "aws_member6_profile" {}
variable "member6_email" {}

variable "aws_member7_account_id" {}
variable "aws_member7_profile" {}
variable "member7_email" {}

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
