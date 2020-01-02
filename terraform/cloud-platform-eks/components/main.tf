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
  config_path = "../files/kubeconfig_${terraform.workspace}"
}

provider "helm" {
  service_account = "tiller"
  kubernetes {
    config_path = "../files/kubeconfig_${terraform.workspace}"
  }
}

###############
# Definitions #
###############

module "components" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-eks-components?ref=0.0.4"

  alertmanager_slack_receivers = var.alertmanager_slack_receivers
  pagerduty_config             = var.pagerduty_config
  cloud_platform_slack_webhook = var.cloud_platform_slack_webhook
}
