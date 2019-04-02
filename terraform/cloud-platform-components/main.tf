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

provider "kubernetes" {}

provider "helm" {
  kubernetes {}
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "cloud-platform/${terraform.workspace}/terraform.tfstate"
    profile = "moj-cp"
  }
}

// This is the kubernetes role that node hosts are assigned.
data "aws_iam_role" "nodes" {
  name = "nodes.${data.terraform_remote_state.cluster.cluster_domain_name}"
}

data "aws_caller_identity" "current" {}

provider "aws" {
  alias   = "dsd"
  profile = "moj-dsd"
  region  = "eu-west-1"
}

locals {
  # This is the list of Route53 Hosted Zones in the DSD account that
  # cert-manager and external-dns will be given access to.
  dsd_zones = [
    "find-legal-advice.justice.gov.uk.",
    "checklegalaid.service.gov.uk.",
  ]

  live_workspace = "test-1"
  live_domain    = "cloud-platform.service.justice.gov.uk"
}
