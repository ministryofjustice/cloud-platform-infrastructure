terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-account"
    profile              = "moj-cp"
    dynamodb_table       = "cloud-platform-terraform-state"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

# IAM configuration for cloud-platform. Users, groups, etc
module "iam" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-iam?ref=0.0.3"

  aws_account_name = "cloud-platform-aws"
}

# Baselines: cloudtrail, cloudwatch, lambda. Everything that our accounts should have
module "baselines" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-baselines?ref=0.0.3"

  enable_logging           = true
  enable_slack_integration = true

  region        = var.aws_region
  slack_webhook = var.slack_config_cloudwatch_lp
  slack_channel = "lower-priority-alarms"

  s3_bucket_block_publicaccess_exceptions = [
    "cloud-platform-9025c5a1a81bca7eaefd78a38df7d7de",
    "cloud-platform-fdc5e4b70a599d8ea84b4ffd31a832b3",
    "cloud-platform-6cf3132ef8fce52bb371b1d02f40c36d"
  ]
}
