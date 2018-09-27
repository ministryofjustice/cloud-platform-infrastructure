variable "project_name" {
  default = "cp-test-2"
}

variable "base_domain_name" {
  default = "cloud-platform.dsd.io"
}

variable "k8s_domain_prefix" {
  default = "k8s"
}

variable "aws_federation_saml_x509_cert" {}
variable "aws_federation_saml_idp_domain" {}
variable "aws_federation_saml_login_url" {}
variable "aws_federation_saml_logout_url" {}
