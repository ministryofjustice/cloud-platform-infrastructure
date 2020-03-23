################################
# Provider Setup & TF Backends #
################################

terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cross-platform-IAM"
    profile              = "moj-cp"
  }
}

provider "aws" {
  profile = "moj-cp"
  region  = "eu-west-2"
}

provider "kubernetes" {
  version = "~> 1.11"
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

// This is the kubernetes role that node hosts are assigned.
data "aws_iam_role" "nodes" {
  name = "nodes.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
}
