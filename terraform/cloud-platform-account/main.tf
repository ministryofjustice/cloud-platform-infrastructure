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

