################################
# Provider Setup & TF Backends #
################################

terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-network"
    profile              = "moj-cp"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

###########################
# Locals & Data Resources #
###########################

locals {
  vpc_name             = terraform.workspace
  vpc_base_domain_name = "${local.vpc_name}.cloud-platform.service.justice.gov.uk"
}

#######
# VPC #
#######

module "vpc" {
  version = "2.18.0"
  source  = "terraform-aws-modules/vpc/aws"

  name                 = local.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = var.availability_zones
  private_subnets      = var.internal_subnets
  public_subnets       = var.external_subnets
  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  public_subnet_tags = {
    SubnetType = "Public"
  }

  private_subnet_tags = {
    SubnetType = "Private"
  }

  tags = {
    Terraform = "true"
  }
}
