terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-components"
    profile              = "moj-cp"
  }
}

provider "aws" {
  profile = "moj-cp"
  region  = "eu-west-2"
}

provider "kubernetes" {
  version = "1.10.0"
}

provider "helm" {
  version = "0.10.4"
  kubernetes {
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "cloud-platform/${terraform.workspace}/terraform.tfstate"
    profile = "moj-cp"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "cloud-platform-network/${terraform.workspace}/terraform.tfstate"
    profile = "moj-cp"
  }
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "global-resources/terraform.tfstate"
    profile = "moj-cp"
  }
}

// This is the kubernetes role that node hosts are assigned.
data "aws_iam_role" "nodes" {
  name = "nodes.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
}

data "aws_caller_identity" "current" {}

# Cloud Platform Helm Chart repository
data "helm_repository" "cloud_platform" {
  name = "cloud-platform"
  url  = "https://ministryofjustice.github.io/cloud-platform-helm-charts"
}

provider "aws" {
  alias   = "dsd"
  profile = "moj-dsd"
  region  = "eu-west-1"
}

locals {
  live_workspace = "live-1"
  live_domain    = "cloud-platform.service.justice.gov.uk"
}

