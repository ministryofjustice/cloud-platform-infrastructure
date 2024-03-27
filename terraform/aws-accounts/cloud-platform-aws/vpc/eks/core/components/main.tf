############################
# Backend & Provider setup #
############################

terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "aws-accounts/cloud-platform-aws/vpc/eks/core/components"
    profile              = "moj-cp"
    dynamodb_table       = "cloud-platform-terraform-state"
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "cloud-platform-aws/vpc/eks/core/components"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    command     = "aws"
  }
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

#################
# Remote States #
#################

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "aws-accounts/cloud-platform-aws/vpc/eks/${terraform.workspace}/terraform.tfstate"
    profile = "moj-cp"
  }
}

##################
# Data Resources #
##################

data "aws_eks_cluster" "cluster" {
  name = terraform.workspace
}

data "aws_route53_zone" "selected" {
  name = "${terraform.workspace}.cloud-platform.service.justice.gov.uk"
}

data "aws_route53_zone" "integrationtest" {
  name = "integrationtest.service.justice.gov.uk"
}

data "aws_route53_zone" "cloud_platform" {
  name = "cloud-platform.service.justice.gov.uk"
}

##########
# Locals #
##########

locals {
  # prod_workspace refer to all production workspaces which have active monitoring set and followed
  prod_workspace = {
    manager = true
    live    = true
    default = false
  }

  # prod_2_workspace is a temporary workspace to include live-2 on the modules that are tested.
  # Once all the modules are tested, this list will replace the prod_workspace
  prod_2_workspace = {
    manager = true
    live    = true
    live-2  = true
    default = false
  }

  # Disable alerts to test clusters by default
  enable_alerts = lookup(local.prod_2_workspace, terraform.workspace, false)

  # live_workspace refer to all production workspaces which have users workload in it
  live_workspace = {
    live    = true
    live-2  = true
    default = false
  }

  manager_workspace = {
    manager = true
    default = false
  }

  hostzones = {
    default = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}",
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.integrationtest.zone_id}"
    ]
    manager = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}",
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.cloud_platform.zone_id}",
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.integrationtest.zone_id}"
    ]
    live   = ["arn:aws:route53:::hostedzone/*"]
    live-2 = ["arn:aws:route53:::hostedzone/*"]
  }
  domain_filters = {
    default = [
      data.aws_route53_zone.selected.name,
      data.aws_route53_zone.integrationtest.name
    ]
    manager = [
      data.aws_route53_zone.selected.name,
      data.aws_route53_zone.cloud_platform.name,
      data.aws_route53_zone.integrationtest.name
    ]
    live   = [""]
    live-2 = [""]
  }
  live1_cert_dns_name = {
    live = format("- '*.apps.%s'", var.live1_domain)
  }
}
