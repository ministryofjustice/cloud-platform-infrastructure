#########
# Setup #
#########

terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "aws-accounts/cloud-platform-aws/vpc/eks"
    profile              = "moj-cp"
    dynamodb_table       = "cloud-platform-terraform-state"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

provider "auth0" {
  domain = local.auth0_tenant_domain
}

###########################
# Locals & Data Resources #
###########################

locals {
  cluster_name             = terraform.workspace
  cluster_base_domain_name = "${local.cluster_name}.cloud-platform.service.justice.gov.uk"
  base_route53_hostzone    = "${local.vpc}.cloud-platform.service.justice.gov.uk"
  key_name                 = "${local.vpc}.cloud-platform.service.justice.gov.uk"

  vpc = lookup(var.vpc_name, terraform.workspace, terraform.workspace)

  auth0_tenant_domain  = "justice-cloud-platform.eu.auth0.com"
  is_live_cluster      = terraform.workspace == "live-1"
  services_base_domain = local.is_live_cluster ? "cloud-platform.service.justice.gov.uk" : "apps.${local.cluster_base_domain_name}"

  is_manager_cluster  = terraform.workspace == "manager"
  is_live_eks_cluster = terraform.workspace == "live"                                                                                 # Live cluster created in EKS also referred to as live-2
  # services_eks_domain = local.is_manager_cluster ? "cloud-platform.service.justice.gov.uk" : "apps.${local.cluster_base_domain_name}" # When live-2 is up and running we will need to amend this operator here to || local.is_live_eks_cluster, or something to that effect.
  services_eks_domain = local.is_manager_cluster ? "cloud-platform.service.justice.gov.uk" : local.cluster_base_domain_name # When live-2 is up and running we will need to amend this operator here to || local.is_live_eks_cluster, or something to that effect.
}

data "aws_route53_zone" "cloud_platform_justice_gov_uk" {
  name = "cloud-platform.service.justice.gov.uk."
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

# #################
# # Route53 / DNS #
# #################

resource "aws_route53_zone" "cluster" {
  name          = "${local.cluster_base_domain_name}."
  force_destroy = true
}

resource "aws_route53_record" "parent_zone_cluster_ns" {
  zone_id = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
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
  source = "github.com/ministryofjustice/cloud-platform-terraform-bastion?ref=1.4.1"

  vpc_name            = local.vpc
  route53_zone        = aws_route53_zone.cluster.name
  cluster_domain_name = local.cluster_base_domain_name
  depends_on = [
    aws_route53_zone.cluster
  ]
}

#########
# Auth0 #
#########

module "auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=1.1.4"

  cluster_name         = local.cluster_name
  services_base_domain = local.services_base_domain
  services_eks_domain  = local.services_eks_domain
  eks                  = true
}
