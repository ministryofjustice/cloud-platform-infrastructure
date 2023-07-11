terraform {
  backend "s3" {
    bucket         = "cloud-platform-terraform-state"
    region         = "eu-west-1"
    key            = "global-resources/terraform.tfstate"
    profile        = "moj-cp"
    dynamodb_table = "cloud-platform-terraform-state"
  }
}

locals {
  auth0_tenant_domain = "justice-cloud-platform.eu.auth0.com"
  auth0_groupsClaim   = "https://k8s.integration.dsd.io/groups"
}

provider "auth0" {
  domain = local.auth0_tenant_domain
}

# default provider
provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "global-resources"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

# https://cloud-platform-aws.signin.aws.amazon.com/console
provider "aws" {
  region  = "eu-west-2"
  alias   = "cloud-platform"
  profile = "moj-cp"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "global-resources"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
  alias   = "cloud-platform-ireland"
  profile = "moj-cp"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "global-resources"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

data "aws_caller_identity" "cloud-platform" {
  provider = aws.cloud-platform
}

provider "external" {
}

data "terraform_remote_state" "account" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "aws-accounts/cloud-platform-aws/account/terraform.tfstate"
    profile = "moj-cp"
  }
}

module "secret_manager" {
  count = terraform.workspace == "live" ? 0 : 1
  source = "github.com/ministryofjustice/cloud-platform-terraform-secrets-manager?ref=2.0.0"

  team_name               = var.team_name
  application             = var.application
  business_unit           = var.business_unit
  is_production           = var.is_production
  namespace               = var.namespace
  environment             = var.environment
  infrastructure_support  = var.infrastructure_support
  eks_cluster_name       = var.eks_cluster_name

  secrets = {
    "slack_webhook_url" = {
      description             = "url used for kibana to post alerts to a channel", // Required
      recovery_window_in_days = 0, // Required
      k8s_secret_name         = "slack_webhook_url" // The name of the secret in k8s
    },
  }
}