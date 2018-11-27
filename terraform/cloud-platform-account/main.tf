terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-account"
  }
}

provider "aws" {
  version = ">= 1.44.0"
  region  = "eu-west-1"
}
