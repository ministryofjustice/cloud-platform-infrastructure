#########
# Setup #
#########

terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-eks"
    profile              = "moj-cp"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

provider "auth0" {
  version = ">= 0.2.0"
  domain  = local.auth0_tenant_domain
}

###########################
# Locals & Data Resources #
###########################

locals {
  cluster_name             = terraform.workspace
  cluster_base_domain_name = "${local.cluster_name}.cloud-platform.service.justice.gov.uk"
  base_route53_hostzone    = "${local.vpc}.cloud-platform.service.justice.gov.uk"
  key_name                 = "${local.vpc}.cloud-platform.service.justice.gov.uk"

  vpc = var.vpc_name == "" ? terraform.workspace : var.vpc_name

  auth0_tenant_domain  = "justice-cloud-platform.eu.auth0.com"
  is_live_cluster      = terraform.workspace == "live-1"
  services_base_domain = local.is_live_cluster ? "cloud-platform.service.justice.gov.uk" : "apps.${local.cluster_base_domain_name}"
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "global-resources/terraform.tfstate"
    profile = "moj-cp"
  }
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [local.vpc]
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    SubnetType = "Utility"
  }
}

# This required by an output (internal_subnets) which is used by 
# concourse. 
data "aws_subnet" "private_cidrs" {
  count = length(tolist(data.aws_subnet_ids.private.ids))
  id    = tolist(data.aws_subnet_ids.private.ids)[count.index]
}

############
# Key Pair #
############

resource "tls_private_key" "vpc" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "aws_key_pair" "vpc" {
  key_name   = local.cluster_base_domain_name
  public_key = tls_private_key.vpc.public_key_openssh
}

# #################
# # Route53 / DNS #
# #################

resource "aws_route53_zone" "cluster" {
  name          = "${local.cluster_base_domain_name}."
  force_destroy = true
}

resource "aws_route53_record" "parent_zone_cluster_ns" {
  zone_id = data.terraform_remote_state.global.outputs.cp_zone_id
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

# ###########
# # BASTION #
# ###########

module "bastion" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-bastion?ref=1.0.0"

  vpc_id         = data.aws_vpc.selected.id
  public_subnets = tolist(data.aws_subnet_ids.public.ids)
  key_name       = aws_key_pair.vpc.key_name
  route53_zone   = aws_route53_zone.cluster.name
}

#########
# Auth0 #
#########

module "auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=0.0.1"

  cluster_name         = local.cluster_name
  services_base_domain = local.services_base_domain
}
