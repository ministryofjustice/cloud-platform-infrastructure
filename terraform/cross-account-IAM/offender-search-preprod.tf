data "aws_iam_policy_document" "offender-search-preprod-kiam-trust-chain" {
  # KIAM trust chain to allow pods to assume roles defined below
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

variable "offender-search-preprod-tags" {
  type = map(string)
  default = {
    business-unit          = "HMPPS"
    application            = "Offender Search Service"
    is-production          = "false"
    environment-name       = "preprod"
    owner                  = "probation-in-court"
    infrastructure-support = "platforms@digital.justice.gov.uk"
  }
}

resource "aws_iam_role" "offender-search-elastic-search-delius-preprod" {
  name               = "offender-search-elastic-search-delius-pre-prod"
  description        = "IAM role for Delius elastic search in preprod"
  tags               = var.offender-search-preprod-tags
  assume_role_policy = data.aws_iam_policy_document.offender-search-preprod-kiam-trust-chain.json
}

resource "kubernetes_secret" "offender-search-elastic-search-delius-preprod-secret" {
  metadata {
    name      = "offender-search-delius-elastic-search-secret"
    namespace = "offender-search-preprod"
  }

  data = {
    arn       = aws_iam_role.offender-search-elastic-search-delius-preprod.arn
    name      = aws_iam_role.offender-search-elastic-search-delius-preprod.name
    unique_id = aws_iam_role.offender-search-elastic-search-delius-preprod.unique_id
  }
}

data "aws_iam_policy_document" "offender-search-elastic-search-delius-preprod" {

  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::010587221707:role/cp-offender-search-service-role-delius-pre-prod"]
  }
}

resource "aws_iam_policy" "offender-search-elastic-search-delius-preprod-policy" {
  name   = "offender-search-elastic-search-delius-preprod-policy"
  policy = data.aws_iam_policy_document.offender-search-elastic-search-delius-preprod.json
}

resource "aws_iam_role_policy_attachment" "offender-search-elastic-search-delius-preprod-policy" {
  role       = aws_iam_role.offender-search-elastic-search-delius-preprod.name
  policy_arn = aws_iam_policy.offender-search-elastic-search-delius-preprod-policy.arn
}