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
  region = "eu-west-2"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "cloud-platform-aws/vpc"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
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

  vpc_cidr = {
    live-1  = "172.20.0.0/16"
    live-2  = "10.195.0.0/16"
    default = "172.20.0.0/16"
  }

  vpc_cidr_eks_prefix = [
    cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, 4),
    cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, 5),
    cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, 6)
  ]
}

#######
# VPC #
#######

module "vpc" {
  version = "5.0.0"
  source  = "terraform-aws-modules/vpc/aws"

  name                    = local.vpc_name
  cidr                    = lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"])
  azs                     = var.availability_zones
  map_public_ip_on_launch = true

  private_subnets = concat([
    cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, 1),
    cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, 2),
    cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, 3)
  ],
   local.vpc_cidr_eks_prefix
  )

  public_subnets = [
    cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 6, 0),
    cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 6, 1),
    cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 6, 2)
  ]

  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

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
  source     = "github.com/ministryofjustice/cloud-platform-terraform-flow-logs?ref=1.3.3"
  is_enabled = terraform.workspace == "live-1" ? true : false
  vpc_id     = module.vpc.vpc_id
}

### Provides a subnet CIDR reservation resource.
resource "aws_ec2_subnet_cidr_reservation" "workers" {
  count = length(local.vpc_cidr_eks_prefix)

  cidr_block       = local.vpc_cidr_eks_prefix[count.index]
  reservation_type = "prefix"
  subnet_id        = data.aws_subnet.selected[count.index].id

  depends_on = [ module.vpc ]
}


data "aws_subnet" "selected" {
  count = length(local.vpc_cidr_eks_prefix)

  cidr_block = local.vpc_cidr_eks_prefix[count.index]
  depends_on = [ module.vpc ]
}