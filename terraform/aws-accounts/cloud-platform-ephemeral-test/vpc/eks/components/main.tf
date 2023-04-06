############################
# Backend & Provider setup #
############################

terraform {
  backend "s3" {
    bucket               = "cloud-platform-ephemeral-test-tfstate"
    region               = "eu-west-2"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "aws-accounts/cloud-platform-ephemeral-test/vpc/eks/components"
    dynamodb_table       = "cloud-platform-ephemeral-test-tfstate"
    profile              = "moj-et"
    encrypt              = true
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-et"
  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "cloud-platform-aws/vpc/eks/components"
      is-production = "false"
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
    bucket  = "cloud-platform-ephemeral-test-tfstate"
    region  = "eu-west-2"
    key     = "aws-accounts/cloud-platform-ephemeral-test/vpc/eks/${terraform.workspace}/terraform.tfstate"
    profile = "moj-et"
  }
}


##################
# Data Resources #
##################

data "aws_eks_cluster" "cluster" {
  name = terraform.workspace
}

data "aws_route53_zone" "selected" {
  name = "${terraform.workspace}.et.cloud-platform.service.justice.gov.uk"
}

data "aws_route53_zone" "cloud_platform_ephemeral_test" {
  name = "et.cloud-platform.service.justice.gov.uk"
}

##########
# Locals #
##########

locals {

  # Disable alerts to test clusters by default
  enable_alerts = lookup(local.prod_2_workspace, terraform.workspace, false)

  prod_2_workspace = {
    manager = true
    live    = true
    live-2  = true
    default = false
  }
  prod_workspace = {
    manager = true
    live    = true
    default = false
  }

  cloudwatch_workspace = {
    manager = false
    live    = true
    live-1  = true
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
    live    = false
    default = false
  }

  hostzones = {
    default = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}",
    ]
  }


  domain_filters = {
    default = [
      data.aws_route53_zone.selected.name,
    ]
  }

  live1_cert_dns_name = {
    live = format("- '*.apps.%s'", var.live1_domain)
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

