locals {
  snapshot_allowed_domains = distinct(concat(
    [local.live_app_logs_domain],
    ["test-restore"]
  ))
}

# Create OpenSearch Snapshot S3 repository
module "s3_bucket_live_app_log" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "${local.live_app_logs_domain}-snapshot-s3-repository"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create IAM role for OpenSearch
data "aws_iam_policy_document" "s3_snapshot_access" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      module.s3_bucket_live_app_log.s3_bucket_arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "${module.s3_bucket_live_app_log.s3_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "s3_snapshot_access" {
  name        = "${local.live_app_logs_domain}-snapshot-s3-access"
  description = "Grants OpenSearch permissions to access S3 for snapshot"
  policy      = data.aws_iam_policy_document.s3_snapshot_access.json
}

data "aws_iam_policy_document" "os_s3_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        for domain_name in local.snapshot_allowed_domains :
        "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${domain_name}"
      ]
    }
  }
}

resource "aws_iam_role" "opensearch_snapshot_role" {
  name               = "${local.live_app_logs_domain}-snapshot-s3-role"
  assume_role_policy = data.aws_iam_policy_document.os_s3_assume_role_policy.json

  managed_policy_arns = [
    aws_iam_policy.s3_snapshot_access.arn
  ]
}

# Mapping IAM role to manage_snapshots so it can register snapshot repositories
resource "opensearch_roles_mapping" "manage_snapshots_mapping" {
  provider    = opensearch.app_logs
  role_name   = "manage_snapshots"
  description = "Mapping IAM roles to manage_snapshots so it can register snapshot repositories"

  backend_roles = [
    aws_iam_role.opensearch_snapshot_role.arn
  ]

  users = []

  depends_on = [
    aws_iam_role.opensearch_snapshot_role
  ]
}

# Attach the s3 repository to the snapshot
resource "opensearch_snapshot_repository" "this" {
  provider = opensearch.app_logs
  name     = "${local.live_app_logs_domain}-snapshot-s3-repository"
  type     = "s3"

  settings = {
    bucket   = module.s3_bucket_live_app_log.s3_bucket_id
    region   = data.aws_region.current.name
    role_arn = aws_iam_role.opensearch_snapshot_role.arn
  }

  depends_on = [
    opensearch_roles_mapping.manage_snapshots_mapping
  ]
}
