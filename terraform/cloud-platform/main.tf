# Setup
terraform {
  backend "s3" {
    bucket = "${var.project_name}-platform-terraform"
    region = "${var.region}"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  version = "~> 1.9.0"
  region  = "${var.region}"
}

data "terraform_remote_state" "global" {
    backend = "s3"
    config {
        bucket = "${project_name}-global-terraform"
        region = "${var.region}"
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
  source             = "terraform-aws-modules/vpc/aws"
  version            = "1.9.1"
  name               = "${local.cluster_name}"
  cidr               = "{var.vpc_cidr}"
  azs                = "{var.availability_zones}"
  private_subnets    = "{var.internal_subnets}"
  public_subnets     = "{var.external_subnets}"
  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Cluster     = "${local.cluster_name}"
    Domain      = "${local.cluster_base_domain_name}"
  }
}
