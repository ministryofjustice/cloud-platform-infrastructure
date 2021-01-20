data "aws_iam_policy_document" "data-eng-rds-dev-kiam-trust-chain" {
  # KIAM trust chain to allow pods to assume roles defined below
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

variable "data-eng-rds-dev-tags" {
  type = map(string)
  default = {
    business-unit          = "HMPPS"
    application            = "data-eng-rds-dev"
    is-production          = "false"
    environment-name       = "dev"
    owner                  = "Probation data engineering"
    infrastructure-support = "platforms@digital.justice.gov.uk"
  }
}

resource "aws_iam_role" "data-eng-rds-dev-ap" {
  name               = "data-eng-rds-dev-ap"
  description        = "IAM role for data-eng-rds-dev to access AP s3 bucket - mojap-land"
  tags               = var.data-eng-rds-dev-tags
  assume_role_policy = data.aws_iam_policy_document.data-eng-rds-dev-kiam-trust-chain.json
}

resource "kubernetes_secret" "ap_landing_bucket_prod" {
  metadata {
    name      = "analytical-platform-landing-bucket"
    namespace = "data-eng-rds-dev"
  }

  data = {
    arn       = aws_iam_role.data-eng-rds-dev-ap.arn
    name      = aws_iam_role.data-eng-rds-dev-ap.name
    unique_id = aws_iam_role.data-eng-rds-dev-ap.unique_id
  }
}

data "aws_iam_policy_document" "data-eng-rds-dev-ap" {

  # allow pods to assume this role
  statement {
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.data-eng-rds-dev-ap.arn]
  }

  # Provide list of permissions and target AWS account resources to allow access from
  statement {
    actions = [
      "s3:PutObject",
      "s3:upload",
      "s3:listObjectsV2",
    ]
    resources = [
      "arn:aws:s3:::mojap-land/hmpps/data-eng-rds-dev/dev/*",
    ]
  }
}

resource "aws_iam_policy" "data-eng-rds-dev-ap-policy" {
  name   = "data-eng-rds-dev-ap-policy"
  policy = data.aws_iam_policy_document.data-eng-rds-dev-ap.json
}

resource "aws_iam_role_policy_attachment" "data-eng-rds-dev-ap-policy" {
  role       = aws_iam_role.data-eng-rds-dev-ap.name
  policy_arn = aws_iam_policy.data-eng-rds-dev-ap-policy.arn
}
