# This is to create IAM role for money-to-prisoners team in namespace money-to-prisoners-test
# to allow assumeRole inside the namespace to access cross account resources.

data "aws_iam_policy_document" "kiam-trust-chain" {
  # KIAM trust chain to allow pods to assume roles defined below
  #   statement {
  #     principals {
  #       type        = "Service"
  #       identifiers = ["ec2.amazonaws.com"]
  #     }
  #     actions = ["sts:AssumeRole"]
  #   }
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::754256621582:role/nodes.live-1.cloud-platform.service.justice.gov.uk"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "api" {
  name               = "money-to-prisoners-test-iam-role-api"
  description        = "IAM role for api pods in money-to-prisoners-test"
  assume_role_policy = data.aws_iam_policy_document.kiam-trust-chain.json
}
data "aws_iam_policy_document" "api" {
  # "api" policy statements
  # allows direct access to a test-only S3 bucket in mojdsd AWS account
  statement {
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::money-to-prisoners-testing/cp/*",
    ]
  }
}


resource "aws_iam_policy" "api" {
  name   = "money-to-prisoners-test-iam-policy-api"
  policy = data.aws_iam_policy_document.api.json
}
resource "aws_iam_role_policy_attachment" "api" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.api.arn
}

resource "kubernetes_secret" "api_output" {
  metadata {
    name      = "api-iam-role"
    namespace = "poornima-dev"
  }

  data = {
    api_iam_role = aws_iam_role.api.id
  }
}
