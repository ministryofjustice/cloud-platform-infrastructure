resource "aws_cloudtrail" "cloud-platform_cloudtrail" {
  provider = aws.ireland

  name                          = "cloud-platform-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  tags = {
    business-unit          = var.business_unit
    owner                  = var.team_name
    infrastructure-support = var.infrastructure_support
  }
}

resource "random_id" "id" {
  byte_length = 4
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  provider = aws.ireland
  bucket   = "${var.cloudtrail_bucket_name}-${random_id.id.hex}"

  tags = {
    business-unit          = var.business_unit
    owner                  = var.team_name
    infrastructure-support = var.infrastructure_support
  }

  lifecycle_rule {
    id                                     = "logs-transition"
    prefix                                 = ""
    abort_incomplete_multipart_upload_days = 7
    enabled                                = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.cloudtrail_bucket_name}-${random_id.id.hex}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.cloudtrail_bucket_name}-${random_id.id.hex}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY

}

