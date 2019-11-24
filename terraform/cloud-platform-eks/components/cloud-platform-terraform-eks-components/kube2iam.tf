#############
#  Kube2IAM #
#############

data "aws_iam_policy_document" "eks-extra" {
  version = "2012-10-17"

  statement {
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
    effect    = "Allow"
  }

  # For ECR
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage",
    ]

    resources = ["*"]
    effect    = "Allow"
  }

}

resource "aws_iam_policy" "eks-policy-default" {
  name   = "${data.terraform_remote_state.cluster.outputs.cluster_domain_name}-default"
  path   = "/"
  policy = data.aws_iam_policy_document.eks-extra.json
}

resource "aws_iam_role_policy_attachment" "eks-attach-default" {
  role       = data.aws_iam_role.nodes.name
  policy_arn = aws_iam_policy.eks-policy-default.arn
}

# This is for kube2iam
data "aws_iam_policy_document" "eks-kube2iam" {
  version = "2012-10-17"

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    #resources = ["arn:aws:iam::${var.account_id}:role/k8s-*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks-kube2iam-policy" {
  name   = "${data.terraform_remote_state.cluster.outputs.cluster_domain_name}-kube2iam-assumerole"
  path   = "/"
  policy = data.aws_iam_policy_document.eks-kube2iam.json
}

resource "aws_iam_role_policy_attachment" "eks-attach-kube2iam" {
  role       = data.aws_iam_role.nodes.name
  policy_arn = aws_iam_policy.eks-kube2iam-policy.arn
}

# Allowing to be assumed, this is gonna be used by every app role

data "aws_iam_policy_document" "allow_to_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
  }
}


########
# Helm #
########

# If user DOESN'T specify custom values file use this resource
resource "helm_release" "kube2iam" {
  count = var.enable_kube2iam ? 1 : 0

  name       = "kube2iam"
  repository = "stable"
  chart      = "kube2iam"
  namespace = "kube2iam"
  version   = "1.0.0"

  values = [templatefile("${path.module}/templates/kube2iam.yaml.tpl", {})]

  depends_on = [
    null_resource.deploy,
  ]
}