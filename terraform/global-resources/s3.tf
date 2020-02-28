locals {
  project_name = "moj-cp-k8s-investigation"
}

resource "aws_s3_bucket" "platform_terraform" {
  bucket = "${local.project_name}-platform-terraform"
  acl    = "private"

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

resource "aws_s3_bucket" "kops_state_store" {
  bucket = "${local.project_name}-kops"
  acl    = "private"

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
}

resource "aws_s3_bucket" "concourse_terraform" {
  bucket = "${local.project_name}-concourse-terraform"
  acl    = "private"

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

resource "aws_s3_bucket" "environments_terraform" {
  bucket = "${local.project_name}-environments-terraform"
  acl    = "private"

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

resource "aws_s3_bucket" "cluster_components" {
  bucket = "cloud-platform-components-terraform"
  acl    = "private"

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
