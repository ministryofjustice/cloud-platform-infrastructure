############################
# Backend & Provider setup #
############################

terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-eks-components"
    profile              = "moj-cp"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

provider "kubernetes" {
  version = "~> 1.11"
}

# Unfortunatly we are facing https://github.com/terraform-providers/terraform-provider-helm/issues/458 and
# https://github.com/terraform-providers/terraform-provider-helm/issues/498 so we can't go to to higher version
provider "helm" {
  version = "1.0.0"
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

resource "null_resource" "calico_deploy" {

  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.5/config/v1.5/calico.yaml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.5/config/v1.5/calico.yaml"
  }
}
