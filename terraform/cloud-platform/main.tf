# Setup
terraform {
  backend "s3" {
    bucket = "moj-cp-k8s-investigation-platform-terraform"
    region = "eu-west-1"
    key = "terraform.tfstate"
  }
}

provider "aws" {
  version = "~> 1.9.0"
  region = "${var.region}"
}

data "terraform_remote_state" "global" {
    backend = "s3"
    config {
        bucket = "moj-cp-k8s-investigation-global-terraform"
        region = "${var.region}"
        key = "terraform.tfstate"
    }
}

locals {
    cluster_name = "${terraform.workspace}"
    cluster_base_domain_name = "${local.cluster_name}.k8s.integration.dsd.io"
}

# Modules
module "cluster_dns" {
    source = "../modules/cluster_dns"

    cluster_base_domain_name = "${local.cluster_base_domain_name}"
    parent_zone_id = "${data.terraform_remote_state.global.k8s_zone_id}"
}

module "cluster_ssl" {
    source = "../modules/cluster_ssl"

    cluster_base_domain_name = "${local.cluster_base_domain_name}"
    dns_zone_id = "${module.cluster_dns.cluster_dns_zone_id}"
}

module "cluster_vpc" {
    source = "../modules/cluster_vpc"

    cidr_block         = "${var.vpc_cidr}"
    name               = "${local.cluster_name}"
    internal_subnets   = ["${var.internal_subnets}"]
    external_subnets   = ["${var.external_subnets}"]
    availability_zones = ["${var.availability_zones}"]
}
