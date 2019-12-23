# -----------------------------------------------------------
# Create Velero Namespace
# -----------------------------------------------------------

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
    #  cluster_domain_name = local.cluster_base_domain_name
  }
}

# -----------------------------------------------------------
# set up S3 bucket
# -----------------------------------------------------------

resource "aws_s3_bucket" "velero" {
  bucket = "cloud-platform-velero-backup-${terraform.workspace}"
  acl    = "private"
  region = "eu-west-2"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "velero" {
  bucket = "cloud-platform-velero-backup-${terraform.workspace}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket.velero,
  ]
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
    resources = ["arn:aws:s3:::cloud-platform-velero-backup-${terraform.workspace}/*"]
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::cloud-platform-velero-backup-${terraform.workspace}"]
  }
}

resource "aws_iam_role_policy" "velero" {
  name   = "velero"
  role   = aws_iam_role.velero.id
  policy = data.aws_iam_policy_document.velero.json
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
