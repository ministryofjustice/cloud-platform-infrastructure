# -----------------------------------------------------------
# set up S3 bucket
# -----------------------------------------------------------

resource "aws_s3_bucket" "velero-test" {
  #  provider      = "aws.cloud-platform-ireland"
  #  bucket_prefix = "${var.bucket_prefix}"
  acl    = "private"
  region = "eu-west-2"

  lifecycle {
    prevent_destroy = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
# -----------------------------------------------------------
# set up IAM role and in-line policy using Kiam
# -----------------------------------------------------------
# Velero
# KIAM role and policy creation
# expressing which roles are permitted to be assumed within that namespace.
# Correct annotation are added to the Pod to indicate which role should be assumed.
# Without correct Pod annotation Kiam cannot provide access to the Pod to execute required actions.

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

    #    resources = ["*"]
    resources = ["arn:aws:s3:::cloud-platform-velero-bucket-test/*"]
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]

    #   resources = ["*"]
    resources = ["arn:aws:s3:::cloud-platform-velero-bucket-test"]
  }
}

resource "aws_iam_role_policy" "velero" {
  name   = "velero"
  role   = aws_iam_role.velero.id
  policy = data.aws_iam_policy_document.velero.json
}

# -----------------------------------------------------------
# Create Velero Namespace
# -----------------------------------------------------------

resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"

    labels = {
      "name"                        = "velero"
      "openpolicyagent.org/webhook" = "ignore"
    }

    annotations = {
      "cloud-platform.justice.gov.uk/application"   = "Velero"
      "cloud-platform.justice.gov.uk/business-unit" = "cloud-platform"
      "cloud-platform.justice.gov.uk/owner"         = "Cloud Platform: platforms@digital.justice.gov.uk"
      "cloud-platform.justice.gov.uk/source-code"   = "https://github.com/ministryofjustice/cloud-platform-infrastructure"
      "iam.amazonaws.com/permitted"                 = aws_iam_role.velero.name
    }
  }
}

data "template_file" "velero" {
  template = file("./templates/velero/velero.yaml.tpl")
  #  vars = {
  #    cluster_domain_name = local.cluster_base_domain_name
  #  }
}

# -----------------------------------------------------------
# Create Velero Helm chart
# -----------------------------------------------------------

resource "helm_release" "velero" {
  name       = "velero"
  namespace  = "velero"
  repository = "stable"
  chart      = "velero"
  version    = "2.3.3"

  depends_on = [
    null_resource.kube_system_ns_label,
    kubernetes_namespace.velero,
    null_resource.deploy,
    aws_iam_role.velero,
    aws_iam_role_policy.velero,
    aws_s3_bucket.velero-test,
  ]
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  values = [
    data.template_file.velero.rendered,
    <<EOF
podAnnotations:
  iam.amazonaws.com/role: "${aws_iam_role.velero.name}"
EOF
    ,
  ]

  lifecycle {
    ignore_changes = [keyring]
  }
}
