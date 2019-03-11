terraform {
  backend "s3" {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "global-resources/terraform.tfstate"
    profile = "moj-cp"
  }
}

locals {
  auth0_tenant_domain = "justice-cloud-platform.eu.auth0.com"
}

provider "auth0" {
  domain = "${local.auth0_tenant_domain}"
}

# default provider
# https://mojds-platforms-integration.signin.aws.amazon.com/console
provider "aws" {
  region  = "eu-west-1"
  profile = "moj-pi"
}

# https://cloud-platform-aws.signin.aws.amazon.com/console
provider "aws" {
  region  = "eu-west-1"
  alias   = "cloud-platform"
  profile = "moj-cp"
}

data "aws_caller_identity" "cloud-platform" {
  provider = "aws.cloud-platform"
}

# https://mojdsd.signin.aws.amazon.com/console
provider "aws" {
  region  = "eu-west-1"
  alias   = "dsd"
  profile = "moj-dsd"
}

provider "external" {}
