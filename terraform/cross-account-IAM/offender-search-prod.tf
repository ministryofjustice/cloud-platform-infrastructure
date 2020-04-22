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
    is-production          = "false"
    environment-name       = "prod"
    owner                  = "probation-in-court"
    infrastructure-support = "platforms@digital.justice.gov.uk"
  }
}

resource "aws_iam_role" "offender-search-elastic-search-delius-prod" {
  name               = "offender-search-elastic-search-delius-prod"
  description        = "IAM role for Delius elastic search in prod"
  tags               = var.offender-search-prod-tags
  assume_role_policy = data.aws_iam_policy_document.offender-search-prod-kiam-trust-chain.json
}

resource "kubernetes_secret" "offender-search-elastic-search-delius-prod-secret" {
  metadata {
    name      = "offender-search-delius-elastic-search-secret"
    namespace = "offender-search-prod"
  }

  data = {
    arn       = aws_iam_role.offender-search-elastic-search-delius-prod.arn
    name      = aws_iam_role.offender-search-elastic-search-delius-prod.name
    unique_id = aws_iam_role.offender-search-elastic-search-delius-prod.unique_id
  }
}

data "aws_iam_policy_document" "offender-search-elastic-search-delius-prod" {

  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::050243167760:role/cp-offender-search-service-role-delius-prod"]
  }
}

resource "aws_iam_policy" "offender-search-elastic-search-delius-prod-policy" {
  name   = "offender-search-elastic-search-delius-prod-policy"
  policy = data.aws_iam_policy_document.offender-search-elastic-search-delius-prod.json
}

resource "aws_iam_role_policy_attachment" "offender-search-elastic-search-delius-prod-policy" {
  role       = aws_iam_role.offender-search-elastic-search-delius-prod.name
  policy_arn = aws_iam_policy.offender-search-elastic-search-delius-prod-policy.arn
}