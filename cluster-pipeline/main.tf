// file: main.tf

provider "aws" {
  region = "${var.fabric_region}"
}

// ---------------------------------------------------------------------------------------------------------------------
// Networking
// ---------------------------------------------------------------------------------------------------------------------

module "main_network" {
  source                  = "github.com/datawire/reference-infrastructure-fabric//modules/vpc"
  cidr_block              = "${var.vpc_cidr}"
  name                    = "${var.fabric_name}"
  internal_subnets        = ["${var.internal_subnets}"]
  external_subnets        = ["${var.external_subnets}"]
  availability_zones      = ["${var.fabric_availability_zones}"]
}
