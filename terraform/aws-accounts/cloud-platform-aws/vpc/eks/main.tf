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
  region = "eu-west-2"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "cloud-platform-aws/vpc/eks"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
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
    live = concat([for i in ["prometheus", "alertmanager", "thanos"] : "https://${i}.${local.fqdn}/oauth2/callback"],
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

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnets" "eks_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    SubnetType = "EKS-Private"
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

# This required by an output (internal_subnets) which is used by
# concourse.
data "aws_subnet" "private_cidrs" {
  count = length(tolist(data.aws_subnets.private.ids))
  id    = tolist(data.aws_subnets.private.ids)[count.index]
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
    aws_route53_zone.cluster.name_servers[0],
    aws_route53_zone.cluster.name_servers[1],
    aws_route53_zone.cluster.name_servers[2],
    aws_route53_zone.cluster.name_servers[3],
  ]
}

#########
# Auth0 #
#########

module "auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=2.1.0"

  cluster_name         = terraform.workspace
  services_base_domain = local.services_base_domain
  extra_callbacks      = lookup(local.auth0_extra_callbacks, terraform.workspace, [""])
}

resource "aws_eks_identity_provider_config" "oidc_associate" {
  // Install OIDC provider on each cluster but offer the option to disable it.
  count        = var.enable_oidc_associate ? 1 : 0
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
