terraform {
  backend "s3" {
    bucket         = "cloud-platform-terraform-state"
    region         = "eu-west-1"
    key            = "global-resources/terraform.tfstate"
    profile        = "moj-cp"
    dynamodb_table = "cloud-platform-terraform-state"
  }
}

locals {
  auth0_tenant_domain = "justice-cloud-platform.eu.auth0.com"
  auth0_groupsClaim   = "https://k8s.integration.dsd.io/groups"
}

provider "auth0" {
  domain = local.auth0_tenant_domain
}

# default provider
provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "global-resources"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

# https://cloud-platform-aws.signin.aws.amazon.com/console
provider "aws" {
  region  = "eu-west-2"
  alias   = "cloud-platform"
  profile = "moj-cp"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "global-resources"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
  alias   = "cloud-platform-ireland"
  profile = "moj-cp"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "global-resources"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

provider "external" {
}

