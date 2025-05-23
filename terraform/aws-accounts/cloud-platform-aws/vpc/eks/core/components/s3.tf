#################################################
# S3 resources for Alertmanager Slack Receivers #
#################################################

module "s3_bucket_alertmanager_slack_receivers" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.3.0"

  count = terraform.workspace == "live" ? 1 : 0

  bucket = "cloud-platform-alertmanager-slack-receivers"

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
