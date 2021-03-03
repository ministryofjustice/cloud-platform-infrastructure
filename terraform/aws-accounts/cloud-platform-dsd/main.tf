
terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket         = "cloud-platform-terraform-state"
    region         = "eu-west-1"
    key            = "cloud-platform-dsd/terraform.tfstate"
    profile        = "moj-cp"
    dynamodb_table = "cloud-platform-terraform-state"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "moj-dsd"
  alias   = "dsd"
}

provider "aws" {
  region  = "eu-west-1"
  profile = "moj-cp"
  alias   = "cp"
}

data "aws_route53_zone" "justice_gov_uk" {
  name     = "service.justice.gov.uk."
  provider = aws.dsd
}

data "aws_route53_zone" "cloud_platform_justice_gov_uk" {
  name     = "cloud-platform.service.justice.gov.uk."
  provider = aws.cp
}

resource "aws_route53_record" "cloud-platform_justice_gov_uk_NS" {
  provider = aws.dsd
  zone_id  = data.aws_route53_zone.justice_gov_uk.zone_id
  name     = data.aws_route53_zone.cloud_platform_justice_gov_uk.name
  type     = "NS"
  ttl      = "300"

  records = data.aws_route53_zone.cloud_platform_justice_gov_uk.name_servers
}

