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

  # Some clusters (like manager) need extra callbacks URLs in auth0
  auth0_extra_callbacks = {
    manager = ["https://sonarqube.cloud-platform.service.justice.gov.uk/oauth2/callback/oidc"]
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
  services_base_domain = local.fqdn
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

#############################
# EKS Cluster vpc cni addon #
#############################

module "irsa_vpc_cni" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "4.6.0"
  create_role                   = true
  role_name                     = "${terraform.workspace}-vpc-cni"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.vpc_cni.arn, "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-node"]
}

resource "aws_iam_policy" "vpc_cni" {
  name        = "${terraform.workspace}-vpc-cni"
  description = "EKS cluster addon for VPC CNI ${terraform.workspace}"
  policy      = data.aws_iam_policy_document.vpc_cni.json
  lifecycle {
    ignore_changes = [name, description]
  }
}

data "aws_iam_policy_document" "vpc_cni" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:AssumeRole"
    ]
    effect = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    resources = ["*"]

  }
}

resource "aws_eks_addon" "cni" {
  depends_on = [module.eks]

  cluster_name             = terraform.workspace
  addon_name               = "vpc-cni"
  addon_version            = "v1.9.3-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = module.irsa_vpc_cni.iam_role_arn
  lifecycle {
    ignore_changes = [cluster_name, addon_name]
  }
  tags = local.tags
}


resource "null_resource" "set_prefix_delegation_target" {
  depends_on = [aws_eks_addon.cni]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks --region eu-west-2 update-kubeconfig --name ${var.cluster_name}
      kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
      kubectl set env daemonset aws-node -n kube-system WARM_PREFIX_TARGET=1
    EOT
  }
  triggers = {
    aws_eks_addon_cni_id = aws_eks_addon.cni.id
  }
}
