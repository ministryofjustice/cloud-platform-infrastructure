# Setup
terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform"
    profile              = "moj-cp"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

# The empty configuration assumes that you have the appropriate environment
# variables exported as explained in the upstream repo and is similar to the way
# the AWS providr credentials are handled.
#
provider "auth0" {
  version = "= 0.12.2"
  domain  = local.auth0_tenant_domain
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
  services_base_domain = local.is_live_cluster ? "cloud-platform.service.justice.gov.uk" : "apps.${local.cluster_base_domain_name}"
  is_manager_cluster   = terraform.workspace == "manager"
  services_eks_domain  = local.is_manager_cluster ? "cloud-platform.service.justice.gov.uk" : "apps.${local.cluster_base_domain_name}"
}

########
# KOPS #
########

module "kops" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kops?ref=0.0.4"

  vpc_name            = local.vpc
  cluster_domain_name = trimsuffix(local.cluster_base_domain_name, ".")
  kops_state_store    = data.terraform_remote_state.global.outputs.cloud_platform_kops_state

  auth0_client_id         = module.auth0.oidc_kubernetes_client_id
  authorized_keys_manager = module.bastion.authorized_keys_manager

  cluster_node_count       = lookup(var.cluster_node_count, terraform.workspace, var.cluster_node_count["default"])
  master_node_machine_type = lookup(var.master_node_machine_type, terraform.workspace, var.master_node_machine_type["default"])
  worker_node_machine_type = lookup(var.worker_node_machine_type, terraform.workspace, var.worker_node_machine_type["default"])
  enable_large_nodesgroup  = lookup(var.enable_large_nodesgroup, terraform.workspace, var.enable_large_nodesgroup["default"])

  template_path   = "../../kops"
  oidc_issuer_url = "https://${local.auth0_tenant_domain}/"
}

# Modules
module "cluster_dns" {
  source                   = "../modules/cluster_dns"
  cluster_base_domain_name = local.cluster_base_domain_name
  parent_zone_id           = data.terraform_remote_state.global.outputs.cp_zone_id
}

###########
# BASTION #
###########

module "bastion" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-bastion?ref=1.3.0"

  vpc_name            = local.vpc
  route53_zone        = module.cluster_dns.cluster_dns_zone_name
  cluster_domain_name = local.cluster_base_domain_name
}

#########
# AUTH0 #
#########

module "auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=1.1.1"

  cluster_name         = local.cluster_name
  services_base_domain = local.services_base_domain
  services_eks_domain  = local.services_eks_domain
}
