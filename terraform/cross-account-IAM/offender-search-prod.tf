data "aws_iam_policy_document" "offender-search-prod-kiam-trust-chain" {
  # KIAM trust chain to allow pods to assume roles defined below
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

variable "offender-search-prod-tags" {
  type = map(string)
  default = {
    business-unit          = "HMPPS"
    application            = "Offender Search Service"
    is-production          = "true"
    environment-name       = "prod"
    owner                  = "probation-in-court"
    infrastructure-support = "platforms@digital.justice.gov.uk"
  }
}

resource "aws_iam_role" "offender-search-prod-delius-elastic-search" {
  name               = "offender-search-prod-delius-elastic-search"
  description        = "IAM role for Delius elastic search in prod"
  tags               = var.offender-search-prod-tags
  assume_role_policy = data.aws_iam_policy_document.offender-search-prod-kiam-trust-chain.json
}

resource "kubernetes_secret" "offender-search-prod-delius-elastic-search-secret" {
  metadata {
    name      = "offender-search-delius-elastic-search-secret"
    namespace = "offender-search-prod"
  }

  data = {
    arn       = aws_iam_role.offender-search-prod-delius-elastic-search.arn
    name      = aws_iam_role.offender-search-prod-delius-elastic-search.name
    unique_id = aws_iam_role.offender-search-prod-delius-elastic-search.unique_id
  }
}

data "aws_iam_policy_document" "offender-search-prod-delius-elastic-search" {

  statement {
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.offender-search-prod-delius-elastic-search.arn]
  }
}

resource "aws_iam_policy" "offender-search-prod-delius-elastic-search-policy" {
  name   = "offender-search-prod-delius-elastic-search-policy"
  policy = data.aws_iam_policy_document.offender-search-prod-kiam-trust-chain.json
}

resource "aws_iam_role_policy_attachment" "offender-search-prod-delius-elastic-search-policy" {
  role       = aws_iam_role.offender-search-prod-delius-elastic-search.name
  policy_arn = aws_iam_policy.offender-search-prod-delius-elastic-search-policy.arn
}