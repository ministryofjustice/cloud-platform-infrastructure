terraform {

  backend "s3" {
    bucket               = "cloud-platform-ephemeral-test-tfstate"
    region               = "eu-west-2"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "aws-accounts/cloud-platform-ephemeral-test/vpc/eks"
    dynamodb_table       = "cloud-platform-ephemeral-test-tfstate"
    encrypt              = true

  }
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket = "cloud-platform-ephemeral-test-tfstate"
    region = "eu-west-2"
    key    = "global-resources/terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-west-2"
}

# Check module source: https://github.com/ministryofjustice/cloud-platform-terraform-auth0
provider "auth0" {
  domain = var.auth0_tenant_domain
}

###########################
# Locals & Data Resources #
###########################

locals {
  account_root_hostzone_name = data.terraform_remote_state.global.outputs.aws_account_hostzone_name
  cluster_name               = terraform.workspace
  cluster_base_domain_name   = "${local.cluster_name}.${local.account_root_hostzone_name}"
  vpc                        = var.vpc_name == "" ? terraform.workspace : var.vpc_name
  auth0_tenant_domain        = "justice-cloud-platform.eu.auth0.com"
  services_base_domain       = "apps.${local.cluster_base_domain_name}"
  services_eks_domain        = "apps.${local.cluster_base_domain_name}"
}

data "aws_route53_zone" "cloud_platform_justice_gov_uk" {
  name = "et.cloud-platform.service.justice.gov.uk."
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [local.vpc]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    SubnetType = "Private"
  }
}

# This is to get subnet_id, to create a separate node group for monitoring with 2 nodes in "eu-west-2b".
data "aws_subnets" "private_zone_2b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "availability-zone"
    values = ["eu-west-2b"]
  }

  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    SubnetType = "Utility"
  }
}

################
# DNS Hostzone #
################

resource "aws_route53_zone" "cluster" {
  name          = local.cluster_base_domain_name
  force_destroy = true
}

resource "aws_route53_record" "parent_zone_cluster_ns" {
  zone_id = data.terraform_remote_state.global.outputs.aws_account_hostzone_id
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

#########
# Auth0 #
#########

module "auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=1.3.0"

  cluster_name         = terraform.workspace
  services_base_domain = local.cluster_base_domain_name
  extra_callbacks      = [""]

}

resource "aws_eks_identity_provider_config" "oidc_associate" {
  cluster_name = terraform.workspace
  depends_on   = [module.eks.cluster_id]
  oidc {
    client_id                     = module.auth0.oidc_kubernetes_client_id
    identity_provider_config_name = "Auth0"
    issuer_url                    = var.auth0_issuerUrl
    username_claim                = "email"
    groups_claim                  = var.auth0_groupsClaim
    required_claims               = {}
  }
}
