################################
# Provider Setup & TF Backends #
################################

terraform {}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    cloudformation = "http://host.docker.internal:4566"
    cloudwatch     = "http://host.docker.internal:4566"
    dynamodb       = "http://host.docker.internal:4566"
    ec2            = "http://host.docker.internal:4566"
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

###########################
# Locals & Data Resources #
###########################

locals {
  vpc_name             = terraform.workspace
  vpc_base_domain_name = "${local.vpc_name}.cloud-platform.service.justice.gov.uk"
  cluster_tags = {
    for name in lookup(var.cluster_names, terraform.workspace, [terraform.workspace]) :
    "kubernetes.io/cluster/${name}" => "shared"
  }
  vpc_tags = merge({
    "kubernetes.io/cluster/${local.vpc_name}" = "shared"
  }, local.cluster_tags)

  prod_workspace = {
    live-raz = true
    default  = false
  }
}

#######
# VPC #
#######

module "vpc" {
  version = "3.14.2"
  source  = "terraform-aws-modules/vpc/aws"

  name                 = local.vpc_name
  cidr                 = var.vpc_cidr
  azs                  = var.availability_zones
  private_subnets      = var.internal_subnets
  public_subnets       = var.external_subnets
  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true

  public_subnet_tags = merge({
    SubnetType               = "Utility"
    "kubernetes.io/role/elb" = "1"
  }, local.cluster_tags)

  private_subnet_tags = merge({
    SubnetType                        = "Private"
    "kubernetes.io/role/internal-elb" = "1"
  }, local.cluster_tags)

  vpc_tags = local.vpc_tags

  tags = {
    Terraform = "true"
    Cluster   = local.vpc_name
    Domain    = local.vpc_base_domain_name
  }
}

### 
module "flowlogs" {
  source     = "github.com/ministryofjustice/cloud-platform-terraform-flow-logs?ref=1.3.2"
  is_enabled = terraform.workspace == true
  vpc_id     = module.vpc.vpc_id
}
