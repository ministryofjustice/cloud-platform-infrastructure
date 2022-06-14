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


data "aws_route53_zone" "cloud_platform" {
  name = "cloud-platform.service.justice.gov.uk"
}

###########################
# Locals & Data Resources #
###########################

locals {
  cluster_name             = terraform.workspace
  cluster_base_domain_name = "${local.cluster_name}.cloud-platform.service.justice.gov.uk"
  vpc                      = var.vpc_name == "" ? terraform.workspace : var.vpc_name

  is_live_cluster      = terraform.workspace == "live-1"
  services_base_domain = local.is_live_cluster ? "cloud-platform.service.justice.gov.uk" : local.cluster_base_domain_name

}

# Modules
module "cluster_dns" {
  source                   = "../../../../modules/cluster_dns"
  cluster_base_domain_name = local.cluster_base_domain_name
  parent_zone_id           = data.aws_route53_zone.cloud_platform.zone_id
}
