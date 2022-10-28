#########
# Setup #
#########

terraform {}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_force_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    cloudformation = "http://host.docker.internal:4566"
    cloudwatch     = "http://host.docker.internal:4566"
    cloudwatchlogs = "http://host.docker.internal:4566"
    dynamodb       = "http://host.docker.internal:4566"
    ec2            = "http://host.docker.internal:4566"
    eks            = "http://host.docker.internal:4566"
    es             = "http://host.docker.internal:4566"
    elasticache    = "http://host.docker.internal:4566"
    iam            = "http://host.docker.internal:4566"
    rds            = "http://host.docker.internal:4566"
    route53        = "http://host.docker.internal:4566"
    s3             = "http://host.docker.internal:4566"
    secretsmanager = "http://host.docker.internal:4566"
    sns            = "http://host.docker.internal:4566"
    sqs            = "http://host.docker.internal:4566"
    ssm            = "http://host.docker.internal:4566"
    sts            = "http://host.docker.internal:4566"
  }
}

provider "auth0" {
  domain = "moj-cloud-platforms-dev.eu.auth0.com"
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

# This is to get subnet_id, to create a separate node group for monitoring with 2 nodes in "eu-west-2b".
data "aws_subnets" "private_zone_2b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east1-1b"]
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
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=1.3.2"

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
