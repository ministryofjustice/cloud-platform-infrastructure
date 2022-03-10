# Setup
terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "aws-accounts/cloud-platform-aws/vpc/kops"
    profile              = "moj-cp"
    dynamodb_table       = "cloud-platform-terraform-state"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

# Because we are querying kops's bucket which is in Ireland 
provider "aws" {
  alias   = "ireland"
  region  = "eu-west-1"
  profile = "moj-cp"
}

# The empty configuration assumes that you have the appropriate environment
# variables exported as explained in the upstream repo and is similar to the way
# the AWS providr credentials are handled.
provider "auth0" {
  domain = local.auth0_tenant_domain
}

data "aws_s3_bucket" "kops_state" {
  bucket   = "cloud-platform-kops-state"
  provider = aws.ireland
}

data "aws_route53_zone" "cloud_platform" {
  name = "cloud-platform.service.justice.gov.uk"
}

###########################
# Locals & Data Resources #
###########################

locals {
  cluster_name             = terraform.workspace
  cluster_base_domain_name = "${local.cluster_name}.cloud-platform.service.justice.gov.uk"
  auth0_tenant_domain      = var.auth0_tenant_domain
  oidc_issuer_url          = "https://${local.auth0_tenant_domain}/"
  vpc                      = var.vpc_name == "" ? terraform.workspace : var.vpc_name

  is_live_cluster      = terraform.workspace == "live-1"
  services_base_domain = local.is_live_cluster ? "cloud-platform.service.justice.gov.uk" : local.cluster_base_domain_name

  # This is to maintain multiple URLs for monitoring stack, in light of the EKS migration
  auth0_extra_callbacks = {
    live-1 = concat([for i in ["prometheus", "alertmanager"] : "https://${i}.${local.cluster_base_domain_name}/oauth2/callback"],
    ["https://grafana.${local.cluster_base_domain_name}/login/generic_oauth"])
  }
}

########
# KOPS #
########

module "kops" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kops?ref=0.2.3"

  vpc_name            = local.vpc
  cluster_domain_name = trimsuffix(local.cluster_base_domain_name, ".")
  kops_state_store    = data.aws_s3_bucket.kops_state.bucket

  auth0_client_id         = module.auth0.oidc_kubernetes_client_id
  authorized_keys_manager = module.bastion.authorized_keys_for_kops

  cluster_node_count_a       = lookup(var.cluster_node_count_a, terraform.workspace, var.cluster_node_count_a["default"])
  cluster_node_count_b       = lookup(var.cluster_node_count_b, terraform.workspace, var.cluster_node_count_b["default"])
  cluster_node_count_c       = lookup(var.cluster_node_count_c, terraform.workspace, var.cluster_node_count_c["default"])
  master_node_machine_type   = lookup(var.master_node_machine_type, terraform.workspace, var.master_node_machine_type["default"])
  worker_node_machine_type   = lookup(var.worker_node_machine_type, terraform.workspace, var.worker_node_machine_type["default"])
  enable_large_nodesgroup    = lookup(var.enable_large_nodesgroup, terraform.workspace, var.enable_large_nodesgroup["default"])
  worker_node_mixed_instance = lookup(var.worker_node_mixed_instance, terraform.workspace, var.worker_node_mixed_instance["default"])

  template_path   = "../../../../../kops"
  oidc_issuer_url = "https://${local.auth0_tenant_domain}/"
}

# Modules
module "cluster_dns" {
  source                   = "../../../../modules/cluster_dns"
  cluster_base_domain_name = local.cluster_base_domain_name
  parent_zone_id           = data.aws_route53_zone.cloud_platform.zone_id
}

###########
# BASTION #
###########

module "bastion" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-bastion?ref=1.5.0"

  vpc_name            = local.vpc
  route53_zone        = module.cluster_dns.cluster_dns_zone_name
  cluster_domain_name = local.cluster_base_domain_name
  depends_on = [
    module.cluster_dns
  ]
}

#########
# AUTH0 #
#########

module "auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=1.2.2"

  cluster_name         = local.cluster_name
  services_base_domain = local.services_base_domain
  extra_callbacks      = lookup(local.auth0_extra_callbacks, terraform.workspace, [""])
}
