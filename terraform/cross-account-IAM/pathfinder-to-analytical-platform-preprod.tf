data "aws_iam_policy_document" "pathfinder-preprod-kiam-trust-chain" {
  # KIAM trust chain to allow pods to assume roles defined below
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

variable "pathfinder-preprod-tags" {
  type = map(string)
  default = {
    business-unit          = "HMPPS"
    application            = "pathfinder"
    is-production          = "false"
    environment-name       = "preprod"
    owner                  = "Digital Prison Services: dps-hmpps@digital.justice.gov.uk"
    infrastructure-support = "platforms@digital.justice.gov.uk"
  }
}

resource "aws_iam_role" "pathfinder-preprod-ap" {
  name               = "pathfinder-preprod-ap"
  description        = "IAM role for pathfinder to access AP s3 bucket - mojap-land"
  tags               = var.pathfinder-preprod-tags
  assume_role_policy = data.aws_iam_policy_document.pathfinder-preprod-kiam-trust-chain.json
}

resource "kubernetes_secret" "analytical_platform_landing_bucket" {
  metadata {
    name      = "analytical-platform-landing-bucket"
    namespace = "pathfinder-preprod"
  }

  data = {
    arn       = aws_iam_role.pathfinder-preprod-ap.arn
    name      = aws_iam_role.pathfinder-preprod-ap.name
    unique_id = aws_iam_role.pathfinder-preprod-ap.unique_id
  }
}

data "aws_iam_policy_document" "pathfinder-preprod-ap" {

  # allow pods to assume this role
  statement {
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.pathfinder-preprod-ap.arn]
  }

  # Provide list of permissions and target AWS account resources to allow access from
  statement {
    actions = [
      "s3:PutObject",
      "s3:listObjectsV2"
    ]
    resources = [
      "arn:aws:s3:::mojap-land/hmpps/pathfinder/preprod/*",
    ]
  }
}

resource "aws_iam_policy" "pathfinder-preprod-ap-policy" {
  name   = "pathfinder-preprod-ap-policy"
  policy = data.aws_iam_policy_document.pathfinder-preprod-ap.json
}

resource "aws_iam_role_policy_attachment" "pathfinder-preprod-ap-policy" {
  role       = aws_iam_role.pathfinder-preprod-ap.name
  policy_arn = aws_iam_policy.pathfinder-preprod-ap-policy.arn
}
