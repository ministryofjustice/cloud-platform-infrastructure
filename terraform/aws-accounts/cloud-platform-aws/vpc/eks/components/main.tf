############################
# Backend & Provider setup #
############################

terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "aws-accounts/cloud-platform-aws/vpc/eks/components"
    profile              = "moj-cp"
    dynamodb_table       = "cloud-platform-terraform-state"
  }
}

provider "aws" {
  region = "eu-west-2"
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

  # prod_2_workspace is a temporary workspace covering all prod std clusters until live-2 is build
  prod_2_workspace = {
    manager = true
    live    = true
    live-2  = true
    default = false
  }

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
    manager = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}",
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.cloud_platform.zone_id}",
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.integrationtest.zone_id}"
    ]
    live = ["arn:aws:route53:::hostedzone/*"]
    default = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}",
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.integrationtest.zone_id}"
    ]
  }
  live1_cert_dns_name = {
    live = format("- '*.apps.%s'", var.live1_domain)
  }

  # live_cluster_colors refer to the color for external-dns set-identifier annotation 
  # set on all production cluster which have users workload in it
  live_cluster_colors = {
    live    = "green"
    live-2  = "blue"
    default = "black"
  }


}

#####################################
# Kube-system annotation and labels #
#####################################

resource "null_resource" "kube_system_default_annotations" {
  provisioner "local-exec" {
    command = "kubectl annotate --overwrite namespace kube-system 'cloud-platform.justice.gov.uk/business-unit=Platforms', 'cloud-platform.justice.gov.uk/application=Cloud Platform', 'cloud-platform.justice.gov.uk/owner=Cloud Platform: platforms@digital.justice.gov.uk', 'cloud-platform.justice.gov.uk/source-code= https://github.com/ministryofjustice/cloud-platform-infrastructure', 'cloud-platform.justice.gov.uk/slack-channel=cloud-platform' 'cloud-platform-out-of-hours-alert=true'"
  }
}
resource "null_resource" "kube_system_default_labels" {
  provisioner "local-exec" {
    command = "kubectl label --overwrite namespace kube-system 'component=kube-system' 'cloud-platform.justice.gov.uk/slack-channel=cloud-platform' 'cloud-platform.justice.gov.uk/is-production=true' 'cloud-platform.justice.gov.uk/environment-name=production'"
  }
}
