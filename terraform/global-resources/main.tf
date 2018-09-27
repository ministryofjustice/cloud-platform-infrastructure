terraform {
  backend "s3" {
    bucket = "cp-test-2-terraform"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  version = "~> 1.9.0"
  region  = "eu-west-1"
}

module "aws_federation" {
  source = "../modules/aws_federation"

  env             = "shared"
  saml_x509_cert  = "${var.aws_federation_saml_x509_cert}"
  saml_idp_domain = "${var.aws_federation_saml_idp_domain}"
  saml_login_url  = "${var.aws_federation_saml_login_url}"
  saml_logout_url = "${var.aws_federation_saml_logout_url}"
}
