#################################################
# S3 resources for Alertmanager Slack Receivers #
#################################################

module "s3_bucket_alertmanager_slack_receivers" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  bucket = "cloud-platform-alertmanager_slack_receivers"
  acl    = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_object" "alertmanager_slack_receivers" {
  bucket = module.s3_bucket_alertmanager_slack_receivers.bucket
  key    = "alertmanager_slack_receivers.json"
  acl    = "private"

  content = jsonencode(var.alertmanager_slack_receivers)

  server_side_encryption = "AES256"
}
