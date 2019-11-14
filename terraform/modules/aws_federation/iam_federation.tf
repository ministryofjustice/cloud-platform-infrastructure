data "template_file" "saml_metadata" {
  template = file("${path.module}/saml/auth0-saml-metadata.xml")

  vars = {
    saml_x509_cert  = var.saml_x509_cert
    saml_idp_domain = var.saml_idp_domain
    saml_login_url  = var.saml_login_url
    saml_logout_url = var.saml_logout_url
  }
}

resource "aws_iam_saml_provider" "auth0" {
  name                   = "${var.env}-auth0"
  saml_metadata_document = data.template_file.saml_metadata.rendered
}

