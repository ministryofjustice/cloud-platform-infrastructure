data "aws_iam_policy_document" "ecr_exporter_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
  }
}

resource "aws_iam_role" "ecr_exporter" {
  name               = "ecr-exporter.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  assume_role_policy = data.aws_iam_policy_document.ecr_exporter_assume.json
}

data "aws_iam_policy_document" "ecr_exporter" {
  statement {
    actions = [
      "ecr:DescribeRepositories",
      "ecr:ListImages",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecr_exporter" {
  name   = "ecr-exporter"
  role   = aws_iam_role.ecr_exporter.id
  policy = data.aws_iam_policy_document.ecr_exporter.json
}

resource "helm_release" "ecr_exporter" {
  name       = "ecr-exporter"
  count      = terraform.workspace == local.live_workspace ? 1 : 0
  namespace  = "monitoring"
  chart      = "prometheus-ecr-exporter"
  repository = data.helm_repository.cloud_platform.metadata[0].name

  set {
    name  = "serviceMonitor.enabled"
    value = true
  }

  set {
    name  = "aws.role"
    value = aws_iam_role.ecr_exporter.name
  }

  set {
    name  = "aws.region"
    value = "eu-west-2"
  }

  depends_on = [
    null_resource.deploy,
    module.prometheus.helm_prometheus_operator_status,
  ]

  lifecycle {
    ignore_changes = [keyring]
  }
}

