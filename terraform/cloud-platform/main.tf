# Setup
terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform"
    profile              = "moj-cp"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

#
#
# The empty configuration assumes that you have the appropriate environment
# variables exported as explained in the upstream repo and is similar to the way
# the AWS providr credentials are handled.
#

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "global-resources/terraform.tfstate"
    profile = "moj-cp"
  }
}

locals {
  cluster_name             = terraform.workspace
  cluster_base_domain_name = "${local.cluster_name}.cloud-platform.service.justice.gov.uk"

  live_workspace = "live-1"
  live_domain    = "cloud-platform.service.justice.gov.uk"
}

# Modules
module "cluster_dns" {
  source                   = "../modules/cluster_dns"
  cluster_base_domain_name = local.cluster_base_domain_name
  parent_zone_id           = data.terraform_remote_state.global.outputs.cp_zone_id
}

module "cluster_ssl" {
  source                   = "../modules/cluster_ssl"
  cluster_base_domain_name = local.cluster_base_domain_name
  dns_zone_id              = module.cluster_dns.cluster_dns_zone_id
}

module "cluster_vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = local.cluster_name
  cidr                 = var.vpc_cidr
  azs                  = var.availability_zones
  private_subnets      = var.internal_subnets
  public_subnets       = var.external_subnets
  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  public_subnet_tags = {
    SubnetType                                                = "Utility"
    "kubernetes.io/cluster/${local.cluster_base_domain_name}" = "shared"
    "kubernetes.io/role/elb"                                  = "1"
  }

  private_subnet_tags = {
    SubnetType                                                = "Private"
    "kubernetes.io/cluster/${local.cluster_base_domain_name}" = "shared"
    "kubernetes.io/role/internal-elb"                         = "1"
  }

  tags = {
    Terraform = "true"
    Cluster   = local.cluster_name
    Domain    = local.cluster_base_domain_name
  }
}

resource "tls_private_key" "cluster" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "aws_key_pair" "cluster" {
  key_name   = local.cluster_base_domain_name
  public_key = tls_private_key.cluster.public_key_openssh
}

