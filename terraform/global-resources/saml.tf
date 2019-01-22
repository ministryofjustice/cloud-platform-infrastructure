resource "auth0_client" "saml" {
  name        = "AWS-SAML: cloud-platform-aws"
  description = "SAML provider for the cloud-platform-aws account"
  app_type    = "regular_web"
  callbacks   = ["https://signin.aws.amazon.com/saml"]


  # This does not currently work as intended. See the output below.
  #
  # addons {
  #   samlp {
  #     audience = "https://signin.aws.amazon.com/saml"
  #
  #     mappings {
  #       email = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
  #       name  = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
  #     }
  #
  #     create_upn_claim                   = false
  #     passthrough_claims_with_no_mapping = false
  #     map_unknown_claims_as_is           = false
  #     map_identities                     = false
  #     name_identifier_format             = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
  #
  #     name_identifier_probes = [
  #       "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
  #     ]
  #   }
  # }
}

output "samlp_configuration" {
  value = <<EOF

=-------------------------------- MANUAL SETUP --------------------------------=

Support for the `samlp` addon in `terraform-provider-auth0` is currently not
producing valid configuration. Therefore, manual activation required.

See https://github.com/yieldr/terraform-provider-auth0/issues/63 for more detail
on the issue.

To finish the setup, please visit

https://manage.auth0.com/#/applications/${auth0_client.saml.client_id}/addons

Enable the SAML2 addon and use the following configuration:

{
  "audience": "https://signin.aws.amazon.com/saml",
  "mappings": {
    "email": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
    "name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
  },
  "createUpnClaim": false,
  "passthroughClaimsWithNoMapping": false,
  "mapUnknownClaimsAsIs": false,
  "mapIdentities": false,
  "nameIdentifierFormat": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
  "nameIdentifierProbes": [
    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier",
    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
  ]
}

=------------------------------------------------------------------------------=

EOF
}

data "external" "metadata" {
  program = [
    "bash",
    "-c",
    "jq -sR '{ content : . }' <<<$(curl -s https://${local.auth0_tenant_domain}/samlp/metadata/${auth0_client.saml.client_id})",
  ]
}

resource "aws_iam_saml_provider" "auth0" {
  provider               = "aws.cloud-platform"
  name                   = "auth0"
  saml_metadata_document = "${data.external.metadata.result["content"]}"
}

data "aws_iam_policy_document" "federated_role_trust_policy" {
  provider = "aws.cloud-platform"

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["${aws_iam_saml_provider.auth0.arn}"]
    }

    actions = ["sts:AssumeRoleWithSAML"]

    condition {
      test     = "StringEquals"
      variable = "SAML:aud"
      values   = ["https://signin.aws.amazon.com/saml"]
    }
  }
}

resource "aws_iam_role" "github_webops" {
  provider             = "aws.cloud-platform"
  name                 = "${auth0_rule_config.aws-saml-role-prefix.value}webops"
  assume_role_policy   = "${data.aws_iam_policy_document.federated_role_trust_policy.json}"
  max_session_duration = "${12 * 3600}"
}

resource "aws_iam_role_policy_attachment" "github_webops_admin" {
  provider   = "aws.cloud-platform"
  role       = "${aws_iam_role.github_webops.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
