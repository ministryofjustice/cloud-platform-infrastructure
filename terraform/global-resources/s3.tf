
resource "aws_s3_bucket" "cloud_platform_kops_state" {
  bucket   = "cloud-platform-kops-state"
  provider = aws.cloud-platform-ireland
  acl      = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  replication_configuration {
    role = aws_iam_role.s3-replication-kops-state.arn
    rules {
      status = "Enabled"
      destination {
        bucket = aws_s3_bucket.cloud_platform_kops_state_replica.arn
      }
    }
  }
  lifecycle {
    ignore_changes = [
      replication_configuration[0].rules,
    ]
  }
}

resource "aws_s3_bucket" "cloud_platform_kops_state_replica" {
  bucket   = "cloud-platform-kops-state-replica"
  acl      = "private"
  provider = aws.cloud-platform

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloud_platform_kops_state_replica" {
  bucket   = "cloud-platform-kops-state-replica"
  provider = aws.cloud-platform

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket.cloud_platform_kops_state_replica,
  ]
}

resource "aws_iam_role" "s3-replication-kops-state" {
  provider    = aws.cloud-platform
  name        = "s3_role_cloud_platform_kops_state"
  description = "Allow S3 to assume the role for replication"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "s3ReplicationAssume",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "s3-replication-kops-state" {
  provider    = aws.cloud-platform
  name        = "s3_cloud_platform_kops_state"
  description = "Allows reading for replication."

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:Get*",
                "s3:ListBucket"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::cloud-platform-kops-state",
                "arn:aws:s3:::cloud-platform-kops-state/*"
            ]
        },
        {
            "Action": [
                "s3:ReplicateObject",
                "s3:ReplicateDelete",
                "s3:ReplicateTags",
                "s3:GetObjectVersionTagging"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::cloud-platform-kops-state-replica/*"
        }
    ]
}
POLICY
}

resource "aws_iam_policy_attachment" "s3-replication-kops-state" {
  provider   = aws.cloud-platform
  name       = "s3_cloud_platform_kops_state_attachment"
  roles      = ["${aws_iam_role.s3-replication-kops-state.name}"]
  policy_arn = aws_iam_policy.s3-replication-kops-state.arn
}

resource "aws_s3_bucket" "velero" {
  bucket   = "cloud-platform-velero-backups"
  acl      = "private"
  provider = aws.cloud-platform

  versioning {
    enabled = true
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
  bucket   = "cloud-platform-velero-backups"
  provider = aws.cloud-platform

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket.velero,
  ]
}

resource "aws_s3_bucket" "thanos" {
  bucket   = "cloud-platform-prometheus-thanos"
  acl      = "private"
  provider = aws.cloud-platform

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "thanos" {
  bucket   = aws_s3_bucket.thanos.id
  provider = aws.cloud-platform

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
