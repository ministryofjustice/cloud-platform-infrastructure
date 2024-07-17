##################
# Data Resources #
##################

data "aws_eks_cluster" "cluster" {
  name = terraform.workspace
}

data "aws_route53_zone" "integrationtest" {
  name = "integrationtest.service.justice.gov.uk"
}

#################
# Remote States #
#################

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "aws-accounts/cloud-platform-aws/vpc/eks/${terraform.workspace}/terraform.tfstate"
    profile = "moj-cp"
  }
}

data "aws_route53_zone" "selected" {
  name = "${terraform.workspace}.cloud-platform.service.justice.gov.uk"
}

data "aws_route53_zone" "cloud_platform" {
  name = "cloud-platform.service.justice.gov.uk"
}