resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"

    labels = {
      "component" = "velero"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"   = "Velero"
      "cloud-platform.justice.gov.uk/business-unit" = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"   = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "iam.amazonaws.com/permitted"                 = ".*"
    }
  }
}

data "template_file" "velero" {
  template = file("./templates/velero/velero.yaml.tpl")
  vars = {
    cluster_name = terraform.workspace
    iam_role     = aws_iam_role.velero.name
  }
}

data "aws_iam_policy_document" "velero_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.nodes.arn]
    }
  }
}

resource "aws_iam_role" "velero" {
  name               = "velero.${data.terraform_remote_state.cluster.outputs.cluster_domain_name}"
  assume_role_policy = data.aws_iam_policy_document.velero_assume.json
}

data "aws_iam_policy_document" "velero" {
  statement {
    actions = [
      "sts:AssumeRole",
      "ec2:DescribeSnapshots",
      "ec2:DescribeVolumes",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["arn:aws:s3:::cloud-platform-velero-backups/*"]
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::cloud-platform-velero-backups"]
  }
}

resource "aws_iam_role_policy" "velero" {
  name   = "velero"
  role   = aws_iam_role.velero.id
  policy = data.aws_iam_policy_document.velero.json
}

resource "helm_release" "velero" {
  name       = "velero"
  namespace  = "velero"
  repository = "stable"
  chart      = "velero"
  version    = "2.3.3"

  depends_on = [
    kubernetes_namespace.velero,
    aws_iam_role.velero,
    aws_iam_role_policy.velero,
  ]
  values = [templatefile("${path.module}/templates/velero/velero.yaml.tpl", {
    cluster_name = terraform.workspace
    iam_role     = aws_iam_role.velero.name
  })]

  lifecycle {
    ignore_changes = [keyring]
  }
}
