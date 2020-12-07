data "aws_iam_policy_document" "pathfinder-prod-kiam-trust-chain" {
  # KIAM trust chain to allow pods to assume roles defined below
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

variable "pathfinder-prod-tags" {
  type = map(string)
  default = {
    business-unit          = "HMPPS"
    application            = "pathfinder"
    is-production          = "true"
    environment-name       = "prod"
    owner                  = "pathfinder"
    infrastructure-support = "platforms@digital.justice.gov.uk"
  }
}

resource "aws_iam_role" "pathfinder-prod-api" {
  name               = "pathfinder-prod-api"
  description        = "IAM role for pathfinder to access AP s3 bucket - mojap-land"
  tags               = var.pathfinder-prod-tags
  assume_role_policy = data.aws_iam_policy_document.pathfinder-prod-kiam-trust-chain.json
}

resource "kubernetes_secret" "analytical_platform_landing_bucket" {
  metadata {
    name      = "analytical_platform_landing_bucket"
    namespace = "pathfinder-prod"
  }

  data = {
    arn       = aws_iam_role.pathfinder-prod-api.arn
    name      = aws_iam_role.pathfinder-prod-api.name
    unique_id = aws_iam_role.pathfinder-prod-api.unique_id
  }
}

data "aws_iam_policy_document" "pathfinder-prod-api" {

  # allow pods to assume this role
  statement {
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.pathfinder-prod-api.arn]
  }

  # Provide list of permissions and target AWS account resources to allow access from
  statement {
    actions = [
      "s3.PutObject",
      "s3.upload",
      "s3.putBucketLifecycleConfiguration",
      "s3.listObjectsV2",
    ]
    resources = [
      "arn:aws:s3:::mojap-land/hmpps/pathfinder/*",
    ]
  }
}

resource "aws_iam_policy" "pathfinder-prod-api-policy" {
  name   = "pathfinder-prod-api-policy"
  policy = data.aws_iam_policy_document.pathfinder-prod-api.json
}

resource "aws_iam_role_policy_attachment" "pathfinder-prod-api-policy" {
  role       = aws_iam_role.pathfinder-prod-api.name
  policy_arn = aws_iam_policy.pathfinder-prod-api-policy.arn
}
