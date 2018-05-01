# Setup
terraform {
  backend "s3" {
    bucket = "moj-cp-k8s-investigation-platform-terraform"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  version = "~> 1.9.0"
  region  = "eu-west-1"
}

data "terraform_remote_state" "global" {
    backend = "s3"
    config {
        bucket = "moj-cp-k8s-investigation-global-terraform"
        region = "eu-west-1"
        key    = "terraform.tfstate"
    }
}

locals {
  cluster_name             = "${terraform.workspace}"
  cluster_base_domain_name = "${local.cluster_name}.k8s.integration.dsd.io"
}

# Modules
module "cluster_dns" {
  source                   = "../modules/cluster_dns"
  cluster_base_domain_name = "${local.cluster_base_domain_name}"
  parent_zone_id           = "${data.terraform_remote_state.global.k8s_zone_id}"
}

module "cluster_ssl" {
  source                   = "../modules/cluster_ssl"
  cluster_base_domain_name = "${local.cluster_base_domain_name}"
  dns_zone_id              = "${module.cluster_dns.cluster_dns_zone_id}"
}

module "cluster_vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "1.9.1"
  name                 = "${local.cluster_name}"
  cidr                 = "${var.vpc_cidr}"
  azs                  = "${var.availability_zones}"
  private_subnets      = "${var.internal_subnets}"
  public_subnets       = "${var.external_subnets}"
  enable_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Terraform   = "true"
    Cluster     = "${local.cluster_name}"
    Domain      = "${local.cluster_base_domain_name}"
  }
}

module "aws_federation" {
    source = "../modules/aws_federation"

    env = "${terraform.workspace}"
    saml_x509_cert = "${var.aws_federation_saml_x509_cert}"
    saml_idp_domain = "${var.aws_federation_saml_idp_domain}"
    saml_login_url = "${var.aws_federation_saml_login_url}"
    saml_logout_url = "${var.aws_federation_saml_logout_url}"
}
