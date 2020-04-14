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

resource "aws_iam_role" "offender-search-dev-delius-elastic-search" {
  name               = "offender-search-dev-delius-elastic-search"
  description        = "IAM role for Delius elastic search in dev"
  tags               = var.offender-search-dev-tags
  assume_role_policy = data.aws_iam_policy_document.offender-search-dev-kiam-trust-chain.json
}

resource "kubernetes_secret" "offender-search-dev-delius-elastic-search-secret" {
  metadata {
    name      = "offender-search-delius-elastic-search-secret"
    namespace = "offender-search-dev"
  }

  data = {
    arn       = aws_iam_role.offender-search-dev-delius-elastic-search.arn
    name      = aws_iam_role.offender-search-dev-delius-elastic-search.name
    unique_id = aws_iam_role.offender-search-dev-delius-elastic-search.unique_id
  }
}

data "aws_iam_policy_document" "offender-search-dev-delius-elastic-search" {

  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::754256621582:cp-pcs-newtech-es-service-role-dev"]
  }
}

resource "aws_iam_policy" "offender-search-dev-delius-elastic-search-policy" {
  name   = "offender-search-dev-delius-elastic-search-policy"
  policy = data.aws_iam_policy_document.offender-search-dev-delius-elastic-search.json
}

resource "aws_iam_role_policy_attachment" "offender-search-dev-delius-elastic-search-policy" {
  role       = aws_iam_role.offender-search-dev-delius-elastic-search.name
  policy_arn = aws_iam_policy.offender-search-dev-delius-elastic-search-policy.arn
}