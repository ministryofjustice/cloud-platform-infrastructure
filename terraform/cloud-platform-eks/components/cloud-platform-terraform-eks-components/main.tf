

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "cloud-platform-eks/${terraform.workspace}/terraform.tfstate"
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

data "aws_iam_role" "nodes" {
  name = data.terraform_remote_state.cluster.outputs.eks_worker_iam_role_name
}

data "aws_route53_zone" "selected" {
  name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}


locals {
  live_workspace = "live-1"
  live_domain    = "cloud-platform.service.justice.gov.uk"
}

