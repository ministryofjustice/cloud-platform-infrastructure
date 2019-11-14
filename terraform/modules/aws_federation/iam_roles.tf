data "aws_iam_policy_document" "federated_role_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_saml_provider.auth0.arn]
    }

    actions = ["sts:AssumeRoleWithSAML"]

    condition {
      test     = "StringEquals"
      variable = "SAML:aud"
      values   = ["https://signin.aws.amazon.com/saml"]
    }
  }
}

# Temporary roles for IAM federation
# These should ultimately be created dynamically based on Github API events
resource "aws_iam_role" "test_github_webops" {
  name = "test-github-webops"

  assume_role_policy = data.aws_iam_policy_document.federated_role_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "test_github_webops_admin" {
  role       = aws_iam_role.test_github_webops.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

