terraform {
  backend "s3" {
    bucket         = "cloud-platform-terraform-state"
    region         = "eu-west-1"
    key            = "aws-accounts/cloud-platform-aws/account/terraform.tfstate"
    profile        = "moj-cp"
    dynamodb_table = "cloud-platform-terraform-state"
  }
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"
}

# Because we are managining kops state in Ireland
provider "aws" {
  alias   = "ireland"
  region  = "eu-west-1"
  profile = "moj-cp"
}

data "aws_caller_identity" "current" {}

# IAM configuration for cloud-platform. Users, groups, etc
module "iam" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-iam?ref=0.0.13"

  aws_account_name = "cloud-platform-aws"
}

# Github SSO
module "sso" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-aws-sso?ref=1.2.1"

  aws_account_id      = data.aws_caller_identity.current.account_id
  auth0_tenant_domain = "justice-cloud-platform.eu.auth0.com"
}

# Baselines: cloudtrail, cloudwatch, lambda. Everything that our accounts should have
module "baselines" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-baselines?ref=0.0.8"

  enable_logging           = true
  enable_slack_integration = true

  region        = var.aws_region
  slack_webhook = var.slack_config_cloudwatch_lp
  slack_channel = "lower-priority-alarms"

  s3_bucket_block_publicaccess_exceptions = [
    "cloud-platform-9025c5a1a81bca7eaefd78a38df7d7de",
    "cloud-platform-fdc5e4b70a599d8ea84b4ffd31a832b3",
    "cloud-platform-6cf3132ef8fce52bb371b1d02f40c36d",
    "cloud-platform-dfc64bcd6ed89a72777fc7924f9da01e",
    "cloud-platform-6c22a751aa9a80bab3ee3706008e9d54",
  ]
}

# Route53 hostzone
resource "aws_route53_zone" "cloud_platform_justice_gov_uk" {
  name = "cloud-platform.service.justice.gov.uk."
}

resource "aws_route53_record" "cloud_platform_justice_gov_uk_TXT" {
  zone_id = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = aws_route53_zone.cloud_platform_justice_gov_uk.name
  type    = "TXT"
  ttl     = "300"
  records = ["google-site-verification=IorKX8xdhHmAEnI4O1LtGPgQwQiFtRJpPFABmzyCN1E"]
}

module "ecr_fluentbit" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials?ref=4.8"

  repo_name = "fluent-bit"
  team_name = "cloud-platform"
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

module "s3_bucket_kubeconfigs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.3.0"

  bucket = "cloud-platform-concourse-kubeconfig"
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

# Create a DynamoDB table so we can lock the terraform state of each
# namespace in the cloud-platform-environments repository, as we
# `terraform apply` it.
#
# This table name is referenced from the environments repo, so that
# terraform can use it to lock the state of each namespace.
resource "aws_dynamodb_table" "cloud_platform_environments_terraform_lock" {
  name           = "cloud-platform-environments-terraform-lock"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  provider = aws.ireland

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table for namespaces in the cloud-platform-environments repository"
  }
}

# Writing kubeconfig within kubeconfig bucket
resource "aws_s3_bucket_object" "kubeconfig" {
  key    = "kubeconfig"
  bucket = module.s3_bucket_kubeconfigs.s3_bucket_id

  content                = templatefile("${path.module}/templates/kubeconfig.tpl", { clusters = var.kubeconfig_clusters })
  server_side_encryption = "AES256"
}

# Schedule Amazon RDS stop and start using AWS Systems Manager

module "aws_scheduler" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-aws-scheduler?ref=0.1.0"

  rds_schedule_expression_stop  = "cron(0 22 ? * * *)"
  rds_schedule_expression_start = "cron(0 06 ? * * *)"
  rds_target_tag_key            = "cloud-platform-rds-auto-shutdown"
  rds_target_tag_value          = "Schedule RDS Stop/Start during non-business hours for cost saving"
}
