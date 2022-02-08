
terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket               = "cloud-platform-ephemeral-test-tfstate"
    region               = "eu-west-2"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-components"
    dynamodb_table       = "cloud-platform-ephemeral-test-tfstate"
    encrypt              = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

provider "kubernetes" {
  version = "~> 1.11"
}

provider "helm" {
  version = "1.1.0"
  kubernetes {
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket = "cloud-platform-ephemeral-test-tfstate"
    region = "eu-west-2"
    key    = "cloud-platform/${terraform.workspace}/terraform.tfstate"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "cloud-platform-ephemeral-test-tfstate"
    region = "eu-west-2"
    key    = "cloud-platform-network/${terraform.workspace}/terraform.tfstate"
  }
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket = "cloud-platform-ephemeral-test-tfstate"
    region = "eu-west-2"
    key    = "global-resources/terraform.tfstate"
  }
}

// This is the kubernetes role that node hosts are assigned.
data "aws_iam_role" "nodes" {
  name = "nodes.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
}

data "aws_caller_identity" "current" {}

locals {
  live_workspace = "live-1"
  live_domain    = "cloud-platform.service.justice.gov.uk"
}

