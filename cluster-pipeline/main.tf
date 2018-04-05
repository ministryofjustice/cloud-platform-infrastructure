// file: main.tf

provider "aws" {
  region = "${var.fabric_region}"
}

// ---------------------------------------------------------------------------------------------------------------------
// Networking
// ---------------------------------------------------------------------------------------------------------------------

module "main_network" {
  source                  = "modules/vpc"

  cidr_block              = "${var.vpc_cidr}"
  name                    = "${var.fabric_name}"
  internal_subnets        = ["${var.internal_subnets}"]
  external_subnets        = ["${var.external_subnets}"]
  availability_zones      = ["${var.fabric_availability_zones}"]
}

module "cluster_dns" {
  source = "../terraform/modules/cluster_dns"

  cluster_base_domain_name = "${var.fabric_region}"
  parent_zone_id = "Z1QX7XOKFA0VGE"
}

module "cluster_ssl" {
  source = "../terraform/modules/cluster_ssl"

  cluster_base_domain_name = "${var.fabric_region}"
  dns_zone_id = "${module.cluster_dns.cluster_dns_zone_id}"
}
