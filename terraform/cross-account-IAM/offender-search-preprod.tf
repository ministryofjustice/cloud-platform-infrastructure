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

resource "aws_iam_role" "offender-search-preprod-delius-elastic-search" {
  name               = "offender-search-preprod-delius-elastic-search"
  description        = "IAM role for Delius elastic search in preprod"
  tags               = var.offender-search-preprod-tags
  assume_role_policy = data.aws_iam_policy_document.offender-search-preprod-kiam-trust-chain.json
}

resource "kubernetes_secret" "offender-search-preprod-delius-elastic-search-secret" {
  metadata {
    name      = "offender-search-delius-elastic-search-secret"
    namespace = "offender-search-preprod"
  }

  data = {
    arn       = aws_iam_role.offender-search-preprod-delius-elastic-search.arn
    name      = aws_iam_role.offender-search-preprod-delius-elastic-search.name
    unique_id = aws_iam_role.offender-search-preprod-delius-elastic-search.unique_id
  }
}

data "aws_iam_policy_document" "offender-search-preprod-delius-elastic-search" {

  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::754256621582:cp-pcs-newtech-es-service-role-pre-prod"]
  }
}

resource "aws_iam_policy" "offender-search-preprod-delius-elastic-search-policy" {
  name   = "offender-search-preprod-delius-elastic-search-policy"
  policy = data.aws_iam_policy_document.offender-search-preprod-kiam-trust-chain.json
}

resource "aws_iam_role_policy_attachment" "offender-search-preprod-delius-elastic-search-policy" {
  role       = aws_iam_role.offender-search-preprod-delius-elastic-search.name
  policy_arn = aws_iam_policy.offender-search-preprod-delius-elastic-search-policy.arn
}