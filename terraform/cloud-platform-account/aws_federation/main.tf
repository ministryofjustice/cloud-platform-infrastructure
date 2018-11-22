provider "aws" {
  version = "~> 1.24.0"
  region  = "eu-west-1"
}

resource "aws_iam_saml_provider" "auth0" {
  name                   = "moj-cloud-platform-aws"
  saml_metadata_document = "${file("saml/moj-cloud-platform-aws_eu_auth0_com-metadata.xml")}"
}

data "aws_iam_policy_document" "federated_role_trust_policy" {
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
  name = "github-webops"

  assume_role_policy = "${data.aws_iam_policy_document.federated_role_trust_policy.json}"
}

resource "aws_iam_role_policy_attachment" "github_webops_admin" {
  role       = "${aws_iam_role.github_webops.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
