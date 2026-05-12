# IAM role for container-platform-github-access GitHub Actions workflow
# Allows the repo to read/write Terraform state in S3 and acquire DynamoDB locks

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "container_platform_github_access_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice/container-platform-github-access:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "container_platform_github_access_state" {
  statement {
    sid    = "AllowS3StateBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::cloud-platform-terraform-state"]
  }

  statement {
    sid    = "AllowS3StateReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::cloud-platform-terraform-state/container-platform-github-access/*"]
  }

  statement {
    sid    = "AllowDynamoDBLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = ["arn:aws:dynamodb:eu-west-1:754256621582:table/cloud-platform-terraform-state"]
  }
}

resource "aws_iam_role" "container_platform_github_access" {
  name               = "container-platform-github-access"
  path               = "/github-actions/"
  assume_role_policy = data.aws_iam_policy_document.container_platform_github_access_assume_role.json

  tags = {
    business-unit          = "OCTO"
    application            = "container-platform-github-access"
    is-production          = "true"
    owner                  = "Cloud Platform: platforms@digital.justice.gov.uk"
    infrastructure-support = "Cloud Platform: platforms@digital.justice.gov.uk"
    source-code            = "github.com/ministryofjustice/container-platform-github-access"
    service-area           = "Hosting"
  }
}

resource "aws_iam_policy" "container_platform_github_access_state" {
  name   = "container-platform-github-access-state"
  path   = "/github-actions/"
  policy = data.aws_iam_policy_document.container_platform_github_access_state.json
}

resource "aws_iam_role_policy_attachment" "container_platform_github_access_state" {
  role       = aws_iam_role.container_platform_github_access.name
  policy_arn = aws_iam_policy.container_platform_github_access_state.arn
}
