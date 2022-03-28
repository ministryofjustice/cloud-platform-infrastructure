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
  domain = "justice-cloud-platform.eu.auth0.com"
}

###########################
# Locals & Data Resources #
###########################

locals {
  fqdn = "${terraform.workspace}.cloud-platform.service.justice.gov.uk"

  vpc = {
    manager = "live-1"
    live    = "live-1"
  }

  is_live_cluster      = terraform.workspace == "live"
  services_base_domain = local.is_live_cluster ? "cloud-platform.service.justice.gov.uk" : local.fqdn

  # Some clusters (like manager) need extra callbacks URLs in auth0
  auth0_extra_callbacks = {
    manager = ["https://sonarqube.cloud-platform.service.justice.gov.uk/oauth2/callback/oidc"]
    live = concat([for i in ["prometheus", "alertmanager"] : "https://${i}.${local.fqdn}/oauth2/callback"],
    ["https://grafana.${local.fqdn}/login/generic_oauth"])
  }
}

data "aws_route53_zone" "cloud_platform_justice_gov_uk" {
  name = "cloud-platform.service.justice.gov.uk."
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [lookup(local.vpc, terraform.workspace, terraform.workspace)]
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    SubnetType = "Private"
  }
}

# This is to get subnet_id, to create a separate node group for monitoring with 2 nodes in "eu-west-2b".
data "aws_subnet_ids" "private_zone_2b" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    SubnetType = "Private"
  }
  filter {
    name   = "availability-zone"
    values = ["eu-west-2b"]
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
  name          = "${terraform.workspace}.cloud-platform.service.justice.gov.uk."
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

#########
# Auth0 #
#########

module "auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=1.2.2"

  cluster_name         = terraform.workspace
  services_base_domain = local.services_base_domain
  extra_callbacks      = lookup(local.auth0_extra_callbacks, terraform.workspace, [""])
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
