terraform {}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    cloudformation = "http://host.docker.internal:4566"
    cloudwatch     = "http://host.docker.internal:4566"
    dynamodb       = "http://host.docker.internal:4566"
    ec2            = "http://host.docker.internal:4566"
    es             = "http://host.docker.internal:4566"
    elasticache    = "http://host.docker.internal:4566"
    iam            = "http://host.docker.internal:4566"
    rds            = "http://host.docker.internal:4566"
    route53        = "http://host.docker.internal:4566"
    s3             = "http://host.docker.internal:4566"
    secretsmanager = "http://host.docker.internal:4566"
    sns            = "http://host.docker.internal:4566"
    sqs            = "http://host.docker.internal:4566"
    ssm            = "http://host.docker.internal:4566"
    sts            = "http://host.docker.internal:4566"
  }
}

data "aws_caller_identity" "current" {}

# Route53 hostzone
resource "aws_route53_zone" "cloud_platform_justice_gov_uk" {
  name = "cloud-platform.service.justice.gov.uk."
}

##############
# S3 buckets #
##############

module "s3_bucket_thanos" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.3.0"

  bucket = "cloud-platform-prometheus-thanos"
  acl    = "private"

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

module "s3_bucket_velero" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "1.18.0"

  bucket = "cloud-platform-velero-backups"
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
