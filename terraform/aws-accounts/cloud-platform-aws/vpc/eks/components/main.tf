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
  region  = "eu-west-2"
  profile = "moj-cp"
}

provider "kubernetes" {}

provider "helm" {
  kubernetes {}
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

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "global-resources/terraform.tfstate"
    profile = "moj-cp"
  }
}

##################
# Data Resources #
##################

data "aws_iam_role" "nodes" {
  name = data.terraform_remote_state.cluster.outputs.eks_worker_iam_role_name
}

data "aws_route53_zone" "selected" {
  name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}

##########
# Locals #
##########

locals {
  live_workspace = "manager"
  live_domain    = "cloud-platform.service.justice.gov.uk"
}

##########
# Calico #
##########

data "kubectl_file_documents" "calico_crds" {
  content = file("${path.module}/resources/calico-crds.yaml")
}

resource "kubectl_manifest" "calico_crds" {
  count     = length(data.kubectl_file_documents.calico_crds.documents)
  yaml_body = element(data.kubectl_file_documents.calico_crds.documents, count.index)
}

resource "helm_release" "calico" {
  name       = "calico"
  chart      = "aws-calico"
  repository = "https://aws.github.io/eks-charts"
  namespace  = "kube-system"
  version    = "0.3.5"

  depends_on = [kubectl_manifest.calico_crds]
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

