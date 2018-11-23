terraform {
  backend "s3" {
    bucket  = "moj-cp-k8s-investigation-global-terraform"
    region  = "eu-west-1"
    key     = "terraform.tfstate"
    profile = "moj-pi"
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "moj-pi"
}

provider "aws" {
  region  = "eu-west-1"
  alias   = "cloud-platform"
  profile = "moj-cp"
}

provider "aws" {
  region  = "eu-west-1"
  alias   = "dsd"
  profile = "moj-dsd"
}

module "aws_federation" {
  source = "../modules/aws_federation"

  env             = "shared"
  saml_x509_cert  = "${var.aws_federation_saml_x509_cert}"
  saml_idp_domain = "${var.aws_federation_saml_idp_domain}"
  saml_login_url  = "${var.aws_federation_saml_login_url}"
  saml_logout_url = "${var.aws_federation_saml_logout_url}"
}
