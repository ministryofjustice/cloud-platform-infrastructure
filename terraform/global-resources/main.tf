terraform {
  required_version = ">= 0.12"
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
}


provider "auth0" {
  version = ">= 0.2.1"
  domain  = local.auth0_tenant_domain
}


# default provider
provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

# https://cloud-platform-aws.signin.aws.amazon.com/console
provider "aws" {
  region  = "eu-west-2"
  alias   = "cloud-platform"
  profile = "moj-cp"
}

provider "aws" {
  region  = "eu-west-1"
  alias   = "cloud-platform-ireland"
  profile = "moj-cp"
}

data "aws_caller_identity" "cloud-platform" {
  provider = aws.cloud-platform
}

# https://mojdsd.signin.aws.amazon.com/console
provider "aws" {
  region  = "eu-west-1"
  alias   = "dsd"
  profile = "moj-dsd"
}

provider "external" {
}

data "terraform_remote_state" "account" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "terraform.tfstate"
    profile = "moj-cp"
  }
}
