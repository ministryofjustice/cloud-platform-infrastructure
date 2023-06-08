terraform {
  backend "s3" {
    bucket         = "cloud-platform-ephemeral-test-tfstate"
    region         = "eu-west-2"
    key            = "global-resources/terraform.tfstate"
    dynamodb_table = "cloud-platform-ephemeral-test-tfstate"
    encrypt        = true
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-et"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "cloud-platform-ephemeral-test/account"
      is-production = "false"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

# data "aws_caller_identity" "current" {}
# data "aws_iam_account_alias" "current" {}
# data "aws_region" "current" {}

###########################
# Security Baseguidelines #
###########################

module "baselines" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-baselines?ref=0.1.1"

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
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-iam?ref=0.0.22"

  aws_account_name = "cloud-platform-ephemeral-test"
}

module "sso" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-aws-sso?ref=1.3.0"

  auth0_tenant_domain = "moj-cloud-platforms-dev.eu.auth0.com"
}

#######
# DNS #
#######

# New parent DNS zone for clusters
resource "aws_route53_zone" "aws_account_hostzone_id" {
  name = "et.cloud-platform.service.justice.gov.uk."
}
