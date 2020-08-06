terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-account"
    profile              = "moj-cp"
  }
}

locals {
  workspace_to_profile = {
    "cloud-platform"              = "moj-cp"
    "mojdsd-platform-integration" = "moj-pi"
  }
}

provider "aws" {
  version = ">= 1.44.0"
  region  = "eu-west-2"
  profile = local.workspace_to_profile[terraform.workspace]
}

provider "aws" {
  region = "eu-west-1"
  alias  = "ireland"
}

# IAM configuration for cloud-platform. Users, groups, etc
module "iam" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-iam?ref=0.0.1"

  aws_account_name = "cloud-platform-aws"
}

module "baselines" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-baselines?ref=main"

  account_name = var.aws_account_name
  region       = var.aws_region

  enable_logging = true
  slack_webhook    = var.baselines_alerts_slack_webhook
  slack_channel    = var.baselines_alerts_slack_channel
}

