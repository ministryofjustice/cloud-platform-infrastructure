
terraform {
  required_version = ">= 0.13"

  backend "s3" {
    bucket               = "cloud-platform-ephemeral-test-tfstate"
    region               = "eu-west-2"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform"
    dynamodb_table       = "cloud-platform-ephemeral-test-tfstate"
    encrypt              = true
  }
}

provider "aws" {
  region = "eu-west-2"
}

# Check module source: https://github.com/ministryofjustice/cloud-platform-terraform-auth0
provider "auth0" {
  domain = var.auth0_tenant_domain
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket = "cloud-platform-ephemeral-test-tfstate"
    region = "eu-west-2"
    key    = "global-resources/terraform.tfstate"
  }
}

data "aws_s3_bucket" "kops_state" {
  bucket = "cloud-platform-ephemeral-test-kops-state"
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
  is_live_cluster            = terraform.workspace == "live-1"
  services_base_domain       = local.is_live_cluster ? "cloud-platform.service.justice.gov.uk" : "apps.${local.cluster_base_domain_name}"
  is_manager_cluster         = terraform.workspace == "manager"
  services_eks_domain        = local.is_manager_cluster ? "cloud-platform.service.justice.gov.uk" : "apps.${local.cluster_base_domain_name}"
}

########
# KOPS #
########

module "kops" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kops?ref=0.1.2"

  vpc_name            = local.vpc
  cluster_domain_name = trimsuffix(local.cluster_base_domain_name, ".")
  kops_state_store    = data.aws_s3_bucket.kops_state.bucket

  auth0_client_id         = module.auth0.oidc_kubernetes_client_id
  authorized_keys_manager = module.bastion.authorized_keys_manager

  cluster_node_count_a       = lookup(var.cluster_node_count_a, terraform.workspace, var.cluster_node_count_a["default"])
  cluster_node_count_b       = lookup(var.cluster_node_count_b, terraform.workspace, var.cluster_node_count_b["default"])
  cluster_node_count_c       = lookup(var.cluster_node_count_c, terraform.workspace, var.cluster_node_count_c["default"])
  master_node_machine_type   = lookup(var.master_node_machine_type, terraform.workspace, var.master_node_machine_type["default"])
  worker_node_machine_type   = lookup(var.worker_node_machine_type, terraform.workspace, var.worker_node_machine_type["default"])
  enable_large_nodesgroup    = lookup(var.enable_large_nodesgroup, terraform.workspace, var.enable_large_nodesgroup["default"])
  enable_ingress_nodesgroup  = lookup(var.enable_ingress_nodesgroup, terraform.workspace, var.enable_ingress_nodesgroup["default"])
  worker_node_mixed_instance = lookup(var.worker_node_mixed_instance, terraform.workspace, var.worker_node_mixed_instance["default"])

  template_path   = "../../../../kops/"
  oidc_issuer_url = "https://${local.auth0_tenant_domain}/"
}

#########
# Auth0 #
#########

module "auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=1.1.4"

  cluster_name         = local.cluster_name
  services_base_domain = local.cluster_base_domain_name
  services_eks_domain  = local.services_eks_domain
  eks                  = true
}

###########
# BASTION #
###########

module "bastion" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-bastion?ref=1.4.1"

  vpc_name            = local.vpc
  route53_zone        = aws_route53_zone.cluster.name
  cluster_domain_name = local.cluster_base_domain_name
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
