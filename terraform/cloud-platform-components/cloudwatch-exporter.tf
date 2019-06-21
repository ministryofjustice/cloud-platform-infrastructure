# Cloudwatch prometheus exporter
# KIAM role creation
# Ref: https://github.com/helm/charts/blob/master/stable/prometheus-cloudwatch-exporter/values.yaml
data "aws_iam_policy_document" "cloudwatch_export_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_iam_role.nodes.arn}"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_exporter" {
  name               = "cloudwatch.${data.terraform_remote_state.cluster.cluster_domain_name}"
  assume_role_policy = "${data.aws_iam_policy_document.external_dns_assume.json}"
}

data "aws_iam_policy_document" "cloudwatch_exporter" {
  statement {
    actions = [
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cloudwatch_exporter" {
  name   = "cloudwatch-exporter"
  role   = "${aws_iam_role.cloudwatch_exporter.id}"
  policy = "${data.aws_iam_policy_document.cloudwatch_exporter.json}"
}

resource "helm_release" "cloudwatch_exporter" {
  name      = "cloudwatch-exporter"
  count     = "${terraform.workspace == local.live_workspace ? 1 : 0}"
  namespace = "monitoring"
  chart     = "stable/prometheus-cloudwatch-exporter"

  values = [
    "${file("./resources/cloudwatch-exporter.yaml")}",
  ]

  set {
    name  = "aws.secret.role"
    value = "${aws_iam_role.cloudwatch_exporter.name}"
  }

  depends_on = [
    "null_resource.deploy",
    "helm_release.prometheus_operator",
  ]
}
