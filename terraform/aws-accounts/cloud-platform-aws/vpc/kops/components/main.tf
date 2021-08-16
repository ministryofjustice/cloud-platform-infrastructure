terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "aws-accounts/cloud-platform-aws/vpc/kops/components"
    profile              = "moj-cp"
    dynamodb_table       = "cloud-platform-terraform-state"
  }
}

provider "aws" {
  profile = "moj-cp"
  region  = "eu-west-2"
}

provider "kubernetes" {}
provider "kubectl" {}

provider "helm" {
  kubernetes {}
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "aws-accounts/cloud-platform-aws/vpc/kops/${terraform.workspace}/terraform.tfstate"
    profile = "moj-cp"
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "aws-accounts/cloud-platform-aws/vpc/${terraform.workspace}/terraform.tfstate"
    profile = "moj-cp"
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

# ServiceAccount creation for concourse in order to access live-1
resource "kubernetes_service_account" "concourse_build_environments" {
  count = terraform.workspace == local.live_workspace ? 1 : 0

  metadata {
    name      = "concourse-build-environments"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "concourse_build_environments" {
  count = terraform.workspace == local.live_workspace ? 1 : 0

  metadata {
    name = "concourse-build-environments"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.concourse_build_environments[0].metadata.0.name
    namespace = "kube-system"
  }
}
