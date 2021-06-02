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

  node_groups_count = {
    live    = "19"
    default = "4"
  }

  node_size = {
    live    = "r5.xlarge"
    manager = "m4.xlarge"
    default = "r5.xlarge"
  }

  # Some clusters (like manage) need extra callbacks URLs in auth0
  auth0_extra_callbacks = {
    manager = ["https://sonarqube.cloud-platform.service.justice.gov.uk/oauth2/callback/oidc"]
  }

  # Add dockerhub crendentials to worker nodes
  dockerhub_credentials = "${var.dockerhub_user}:${var.dockerhub_token}"
  dockerhub_file        = <<-EOD
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "${base64encode(local.dockerhub_credentials)}"
    }
  }
}
EOD
  pre_userdata          = <<-EOD
mkdir -p "/root/.docker"
echo '${local.dockerhub_file}' > "/root/.docker/config.json"
mkdir -p "/var/lib/kubelet/.docker"
echo '${local.dockerhub_file}' > "/var/lib/kubelet/config.json"
EOD
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
  source = "github.com/ministryofjustice/cloud-platform-terraform-auth0?ref=1.2.0"

  cluster_name         = terraform.workspace
  services_base_domain = "apps.${local.fqdn}"
  extra_callbacks      = lookup(local.auth0_extra_callbacks, terraform.workspace, null)
}
