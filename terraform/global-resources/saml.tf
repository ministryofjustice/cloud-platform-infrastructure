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
