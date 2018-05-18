variable "project_name" {
  default = "moj-cp-k8s-investigation"
}

variable "base_domain_name" {
  default = "integration.dsd.io"
}

variable "k8s_domain_prefix" {
  default = "k8s"
}

variable "aws_federation_saml_x509_cert" {}
variable "aws_federation_saml_idp_domain" {}
variable "aws_federation_saml_login_url" {}
variable "aws_federation_saml_logout_url" {}
