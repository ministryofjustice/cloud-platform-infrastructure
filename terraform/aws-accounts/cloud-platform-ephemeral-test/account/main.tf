terraform {
  backend "s3" {
    bucket         = "cloud-platform-ephemeral-test-tfstate"
    region         = "eu-west-2"
    key            = "global-resources/terraform.tfstate"
    dynamodb_table = "cloud-platform-ephemeral-test-tfstate"
    encrypt        = true
  }
}

provider "github" {}

provider "aws" {
  region = "eu-west-2"
}

data "aws_caller_identity" "current" {}

###########################
# Security Baseguidelines #
###########################

module "baselines" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-baselines?ref=0.0.8"

  enable_logging           = true
  enable_slack_integration = true

  region        = var.aws_region
  slack_webhook = var.slack_config_cloudwatch_lp
  slack_channel = "lower-priority-alarms"
}

#######
# IAM #
#######

module "iam" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-iam?ref=0.0.13"

  aws_account_name = "cloud-platform-ephemeral-test"
}

module "sso" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-aws-sso?ref=1.1.0"

  aws_account_id      = data.aws_caller_identity.current.account_id
  auth0_tenant_domain = "moj-cloud-platforms-dev.eu.auth0.com"
}

#######
# DNS #
#######

# New parent DNS zone for clusters
resource "aws_route53_zone" "aws_account_hostzone_id" {
  name = "et.cloud-platform.service.justice.gov.uk."
}

###################
# Automated tests #
###################

# This module creates an AWS user and injest AWS_* keys within the specified 
# GH repos in order to be used by the GH actions to execute unit-tests
module "terratest" {
  count  = 0
  source = "./modules/automated-tests"

  github_repositories = [
    "cloud-platform-terraform-ecr-credentials",
    "cloud-platform-terraform-sqs",
  ]
}
