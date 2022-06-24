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

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    command     = "aws"
  }
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
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

data "aws_eks_cluster_auth" "cluster" {
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

  manager_workspace = {
    manager = true
    live    = false
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
}

##########
# Calico #
##########
resource "kubernetes_namespace" "tigera_operator" {
  metadata {
    name = "tigera-operator"

    labels = {
      "component" = "networking"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "Networking"
      "cloud-platform.justice.gov.uk/business-unit"              = "Platforms"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "iam.amazonaws.com/permitted"                              = ".*"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
      "cloud-platform-out-of-hours-alert"                        = "true"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "kubernetes_namespace" "calico_system" {
  metadata {
    name = "calico-system"

    labels = {
      "component"                    = "networking"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"                = "Networking"
      "cloud-platform.justice.gov.uk/business-unit"              = "Platforms"
      "cloud-platform.justice.gov.uk/owner"                      = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"                = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "iam.amazonaws.com/permitted"                              = ".*"
      "cloud-platform.justice.gov.uk/can-tolerate-master-taints" = "true"
      "cloud-platform-out-of-hours-alert"                        = "true"
    }
  }

  lifecycle {
    ignore_changes = [metadata]
  }
}

// Copied from https://github.com/projectcalico/calico/tree/release-v3.21/libcalico-go/config/crd
data "kubectl_filename_list" "calico_crds" {
  pattern = "${path.module}/resources/crd.projectcalico.org*yaml"
}
resource "kubectl_manifest" "calico_crds" {
  count     = length(data.kubectl_filename_list.calico_crds.matches)
  yaml_body = file(element(data.kubectl_filename_list.calico_crds.matches, count.index))
}

resource "helm_release" "calico" {
  name       = "tigera-operator"
  chart      = "tigera-operator"
  repository = "https://docs.projectcalico.org/charts"
  namespace  = "tigera-operator"
  version    = "v3.23.1"
  timeout    = "900"

  set {
    name  = "installation.kubernetesProvider"
    value = "EKS"
  }

  depends_on = [
    kubernetes_namespace.tigera_operator,
    kubernetes_namespace.calico_system,
    kubectl_manifest.calico_crds
  ]
}

data "kubectl_file_documents" "calico_global_policies" {
  content = file("${path.module}/resources/calico-global-policies.yaml")
}

resource "kubectl_manifest" "calico_global_policies" {
  count     = length(data.kubectl_file_documents.calico_global_policies.documents)
  yaml_body = element(data.kubectl_file_documents.calico_global_policies.documents, count.index)

  depends_on = [helm_release.calico]
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

