######################
# cluster-autoscaler #
######################

#
# HELM
#

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  repository = "stable"
  chart      = "cluster-autoscaler"

  namespace = "kube-system"
  version   = "6.2.0"

  values = [templatefile("${path.module}/templates/cluster-autoscaler.yaml.tpl", {
    cluster_name = terraform.workspace
    iam_role     = aws_iam_role.clusterautoscaller.name
  })]

}

#
# IAM bits
#

resource "aws_iam_role" "clusterautoscaller" {
  name = "clusterautoscaller.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  assume_role_policy = data.aws_iam_policy_document.allow_to_assume.json
}

data "aws_iam_policy_document" "clusterautoscaller" {

  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = ["*"]
    effect    = "Allow"
  }

}

resource "aws_iam_role_policy_attachment" "clusterautoscaller_attach_policy" {
  role       = aws_iam_role.clusterautoscaller.name
  policy_arn = aws_iam_policy.clusterautoscaller.arn
}

resource "aws_iam_policy" "clusterautoscaller" {
  name        = "clusterautoscaller.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  path        = "/"
  description = "Policy that allows change update ASGs for the workers service"
  policy      = data.aws_iam_policy_document.clusterautoscaller.json
}


