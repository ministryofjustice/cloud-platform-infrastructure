data "aws_iam_policy_document" "offender-search-dev-kiam-trust-chain" {
  # KIAM trust chain to allow pods to assume roles defined below
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
    actions = ["sts:AssumeRole"]
  }
}

variable "offender-search-dev-tags" {
  type = map(string)
  default = {
    business-unit          = "HMPPS"
    application            = "Offender Search Service"
    is-production          = "false"
    environment-name       = "dev"
    owner                  = "probation-in-court"
    infrastructure-support = "platforms@digital.justice.gov.uk"
  }
}

resource "aws_iam_role" "offender-search-elastic-search-delius-dev" {
  name               = "offender-search-elastic-search-delius-dev"
  description        = "IAM role for Delius elastic search in dev"
  tags               = var.offender-search-dev-tags
  assume_role_policy = data.aws_iam_policy_document.offender-search-dev-kiam-trust-chain.json
}

resource "kubernetes_secret" "offender-search-elastic-search-delius-dev-secret" {
  metadata {
    name      = "offender-search-delius-elastic-search-secret"
    namespace = "offender-search-dev"
  }

  data = {
    arn       = aws_iam_role.offender-search-elastic-search-delius-dev.arn
    name      = aws_iam_role.offender-search-elastic-search-delius-dev.name
    unique_id = aws_iam_role.offender-search-elastic-search-delius-dev.unique_id
  }
}

data "aws_iam_policy_document" "offender-search-elastic-search-delius-dev" {

  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::723123699647:role/cp-offender-search-service-role-delius-core-dev"]
  }
}

resource "aws_iam_policy" "offender-search-elastic-search-delius-dev-policy" {
  name   = "offender-search-elastic-search-delius-dev-policy"
  policy = data.aws_iam_policy_document.offender-search-elastic-search-delius-dev.json
}

resource "aws_iam_role_policy_attachment" "offender-search-elastic-search-delius-dev-policy" {
  role       = aws_iam_role.offender-search-elastic-search-delius-dev.name
  policy_arn = aws_iam_policy.offender-search-elastic-search-delius-dev-policy.arn
}
