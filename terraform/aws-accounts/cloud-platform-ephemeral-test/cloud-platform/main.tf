terraform {

  backend "s3" {
    bucket               = "cloud-platform-ephemeral-test-tfstate"
    region               = "eu-west-2"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform"
    dynamodb_table       = "cloud-platform-ephemeral-test-tfstate"
    encrypt              = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

# Check module source: https://github.com/ministryofjustice/cloud-platform-terraform-auth0
provider "auth0" {
  domain = var.auth0_tenant_domain
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket = "cloud-platform-ephemeral-test-tfstate"
    region = "eu-west-2"
    key    = "global-resources/terraform.tfstate"
  }
}

data "aws_s3_bucket" "kops_state" {
  bucket = "cloud-platform-ephemeral-test-kops-state"
}

###########################
# Locals & Data Resources #
###########################

locals {
  account_root_hostzone_name = data.terraform_remote_state.global.outputs.aws_account_hostzone_name
  cluster_name               = terraform.workspace
  cluster_base_domain_name   = "${local.cluster_name}.${local.account_root_hostzone_name}"
  vpc                        = var.vpc_name == "" ? terraform.workspace : var.vpc_name
  auth0_tenant_domain        = "justice-cloud-platform.eu.auth0.com"
  services_base_domain       = "apps.${local.cluster_base_domain_name}"
  services_eks_domain        = "apps.${local.cluster_base_domain_name}"
}

#########
# Auth0 #
#########

module "auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=1.2.2"

  cluster_name         = terraform.workspace
  services_base_domain = local.cluster_base_domain_name
  extra_callbacks      = [""]

}

################
# DNS Hostzone #
################

resource "aws_route53_zone" "cluster" {
  name          = local.cluster_base_domain_name
  force_destroy = true
}

resource "aws_route53_record" "parent_zone_cluster_ns" {
  zone_id = data.terraform_remote_state.global.outputs.aws_account_hostzone_id
  name    = aws_route53_zone.cluster.name
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.cluster.name_servers.0,
    aws_route53_zone.cluster.name_servers.1,
    aws_route53_zone.cluster.name_servers.2,
    aws_route53_zone.cluster.name_servers.3,
  ]
}
