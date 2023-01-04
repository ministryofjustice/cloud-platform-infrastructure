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
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.cloud_platform_ephemeral_test.zone_id}",
    ]
    live = ["arn:aws:route53:::hostedzone/*"]
    default = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}",
    ]
  }
  live1_cert_dns_name = {
    live = format("- '*.apps.%s'", var.live1_domain)
  }
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
  version    = "0.3.10"

  depends_on = [kubectl_manifest.calico_crds]
  timeout    = "900"

  set {
    name  = "calico.typha.resources.limits.memory"
    value = "256Mi"
  }
  set {
    name  = "calico.typha.resources.limits.cpu"
    value = "200m"
  }
  set {
    name  = "calico.node.resources.limits.memory"
    value = "128Mi"
  }
  set {
    name  = "calico.node.resources.limits.cpu"
    value = "200m"
  }
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

