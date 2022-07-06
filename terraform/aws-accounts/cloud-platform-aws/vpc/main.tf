################################
# Provider Setup & TF Backends #
################################

terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "aws-accounts/cloud-platform-aws/vpc"
    profile              = "moj-cp"
    dynamodb_table       = "cloud-platform-terraform-state"
  }
}

provider "aws" {
  region  = "eu-west-2"
}

###########################
# Locals & Data Resources #
###########################

locals {
  vpc_name             = terraform.workspace
  vpc_base_domain_name = "${local.vpc_name}.cloud-platform.service.justice.gov.uk"
  cluster_tags = {
    for name in lookup(var.cluster_names, terraform.workspace, [terraform.workspace]) :
    "kubernetes.io/cluster/${name}" => "shared"
  }
  vpc_tags = merge({
    "kubernetes.io/cluster/${local.vpc_name}" = "shared"
  }, local.cluster_tags)
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

  public_subnet_tags = merge({
    SubnetType               = "Utility"
    "kubernetes.io/role/elb" = "1"
  }, local.cluster_tags)

  private_subnet_tags = merge({
    SubnetType                        = "Private"
    "kubernetes.io/role/internal-elb" = "1"
  }, local.cluster_tags)

  vpc_tags = local.vpc_tags

  tags = {
    Terraform = "true"
    Cluster   = local.vpc_name
    Domain    = local.vpc_base_domain_name
  }
}

### 
module "flowlogs" {
  source     = "github.com/ministryofjustice/cloud-platform-terraform-flow-logs?ref=1.3"
  is_enabled = terraform.workspace == "live-1" ? true : false
  vpc_id     = module.vpc.vpc_id
}
