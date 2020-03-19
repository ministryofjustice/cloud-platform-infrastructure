# Setup
terraform {
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

#
# See instructions here: https://github.com/ministryofjustice/kubernetes-investigations/tree/master/auth0
#              and here: https://github.com/yieldr/terraform-provider-auth0
#
# The empty configuration assumes that you have the appropriate environment
# variables exported as explained in the upstream repo and is similar to the way
# the AWS providr credentials are handled.
#
provider "auth0" {
  version = ">= 0.2.1"
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
  auth0_tenant_domain      = "justice-cloud-platform.eu.auth0.com"
  oidc_issuer_url          = "https://${local.auth0_tenant_domain}/"
  vpc                      = var.vpc_name == "" ? terraform.workspace : var.vpc_name

  is_live_cluster      = terraform.workspace == "live-1"
  services_base_domain = local.is_live_cluster ? "cloud-platform.service.justice.gov.uk" : "apps.${local.cluster_base_domain_name}"
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

# Unfortunately data.template_file.kops resource only receives individual subnets with the 
# AZs already mapped. Since terraform 0.12 there is a better way to do it using templatefile 
# ( https://www.terraform.io/docs/configuration/functions/templatefile.html ) and passing 
# the whole array of subnets with AZ included, it will involve using a something like 
# %{ for subnets in subnets_all ~} # inside the templates/kops.yaml.tpl. For this PR the 
# idea is to change the least possible, following PRs will be coming to make it better.

data "aws_subnet" "private_a" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "eu-west-2a"

  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnet" "private_b" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "eu-west-2b"

  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnet" "private_c" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "eu-west-2c"

  tags = {
    SubnetType = "Private"
  }
}

data "aws_subnet" "public_a" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "eu-west-2a"

  tags = {
    SubnetType = "Utility"
  }
}

data "aws_subnet" "public_b" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "eu-west-2b"

  tags = {
    SubnetType = "Utility"
  }
}

data "aws_subnet" "public_c" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "eu-west-2c"

  tags = {
    SubnetType = "Utility"
  }
}


# Modules
module "cluster_dns" {
  source                   = "../modules/cluster_dns"
  cluster_base_domain_name = local.cluster_base_domain_name
  parent_zone_id           = data.terraform_remote_state.global.outputs.cp_zone_id
}

module "cluster_ssl" {
  source                   = "../modules/cluster_ssl"
  cluster_base_domain_name = local.cluster_base_domain_name
  dns_zone_id              = module.cluster_dns.cluster_dns_zone_id
}

resource "tls_private_key" "cluster" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "aws_key_pair" "cluster" {
  key_name   = local.cluster_base_domain_name
  public_key = tls_private_key.cluster.public_key_openssh
}

resource "auth0_client" "kubernetes" {
  name        = "${local.cluster_name}:kubernetes"
  description = "Cloud Platform kubernetes"
  app_type    = "regular_web"

  callbacks = [format("https://login.%s/ui", local.services_base_domain)]

  custom_login_page_on = true
  is_first_party       = true
  oidc_conformant      = true
  sso                  = true

  jwt_configuration {
    alg                 = "RS256"
    lifetime_in_seconds = "2592000"
  }
}

resource "auth0_client" "components" {
  name        = "${local.cluster_name}:components"
  description = "Cloud Platform components"
  app_type    = "regular_web"

  callbacks = [
    format(
      "https://prometheus.%s/oauth2/callback",
      local.services_base_domain,
    ),
    format(
      "https://alertmanager.%s/oauth2/callback",
      local.services_base_domain,
    ),
    format(
      "https://concourse.%s/sky/issuer/callback",
      local.services_base_domain,
    ),
    format(
      "https://kibana.%s/oauth2/callback",
      local.services_base_domain,
    ),
    format(
      "https://kibana-audit.%s/oauth2/callback",
      local.services_base_domain,
    ),
    #This call back is for kibana in dsd account.
    format(
      "https://dsd-kibana.apps.live-1.%s/oauth2/callback",
      local.services_base_domain,
    ),
    format(
      "https://grafana.%s/login/generic_oauth",
      local.services_base_domain,
    ),
    format(
      "https://kube-ops.%s/login/authorized",
      local.services_base_domain,
    ),
  ]

  custom_login_page_on = true
  is_first_party       = true
  oidc_conformant      = true
  sso                  = true

  jwt_configuration {
    alg                 = "RS256"
    lifetime_in_seconds = "36000"
  }
}

