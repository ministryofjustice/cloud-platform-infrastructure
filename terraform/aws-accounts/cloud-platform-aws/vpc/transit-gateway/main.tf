terraform {

  backend "s3" {
    bucket  = "cloud-platform-terraform-state"
    key     = "transit-gateway/terraform.tfstate"
    region  = "eu-west-1"
    profile = "moj-cp"
  }
}

# get access to live-1 VPC state
# Necessary to get route_table_ids
# This is shared VPC for "live" and "manager" clusters
data "terraform_remote_state" "cluster-network" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "aws-accounts/cloud-platform-aws/vpc/live-1/terraform.tfstate"
    profile = "moj-cp"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

data "aws_caller_identity" "current" {
}
