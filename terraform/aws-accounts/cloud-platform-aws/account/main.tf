terraform {
  backend "s3" {
    bucket         = "cloud-platform-terraform-state"
    region         = "eu-west-1"
    key            = "aws-accounts/cloud-platform-aws/account/terraform.tfstate"
    profile        = "moj-cp"
    dynamodb_table = "cloud-platform-terraform-state"
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

provider "aws" {
  region  = "eu-west-2"
  profile = "moj-cp"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "cloud-platform-aws/account"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

# Because we are managining kops state in Ireland
provider "aws" {
  alias   = "ireland"
  region  = "eu-west-1"
  profile = "moj-cp"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "cloud-platform-aws/account"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

# get access to live-1 VPC state
# Necessary to get flowlogs bucket id/arn for SQS
data "terraform_remote_state" "live-1" {
  backend = "s3"
  config = {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "aws-accounts/cloud-platform-aws/vpc/live-1/terraform.tfstate"
    profile = "moj-cp"
  }
}

# used for cloudfront/waf
provider "aws" {
  alias  = "northvirginia"
  region = "us-east-1"

  default_tags {
    tags = {
      business-unit = "Platforms"
      application   = "cloud-platform-aws/account"
      is-production = "true"
      owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
      source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_iam_account_alias" "current" {}
data "aws_region" "current" {}

# IAM configuration for cloud-platform. Users, groups, OIDC providers etc
module "iam" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-iam?ref=0.0.34"

  aws_account_name         = "cloud-platform-aws"
  circleci_organisation_id = jsondecode(data.aws_secretsmanager_secret_version.circleci.secret_string)["organisation_id"]
}

# Github SSO
module "sso" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-aws-sso?ref=1.5.9"

  auth0_tenant_domain = "justice-cloud-platform.eu.auth0.com"
}

# Baselines: cloudtrail, cloudwatch, lambda. Everything that our accounts should have
module "baselines" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-awsaccounts-baselines?ref=0.2.2"

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

##############
# S3 buckets #
##############

module "s3_bucket_thanos" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

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
  version = "2.14.0" # 2.15 pins to terraform-aws-provider <= 4, so this module needs to be upgraded to 3.6.0, which has some resource changes (which may require manual intervention for terraform state imports)

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
  version = "3.15.1"

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
  source = "github.com/ministryofjustice/cloud-platform-terraform-aws-scheduler?ref=0.1.1"

  rds_schedule_expression_stop  = "cron(0 22 ? * * *)"
  rds_schedule_expression_start = "cron(0 06 ? * * *)"
  rds_target_tag_key            = "cloud-platform-rds-auto-shutdown"
  rds_target_tag_value          = "Schedule RDS Stop/Start during non-business hours for cost saving"
}

# IAM Role for Operations Engineering Account Route53 readonly access

resource "aws_iam_role" "ops_eng_route53_readonly" {
  name               = "ops-eng-route53-readonly"
  assume_role_policy = data.aws_iam_policy_document.ops_eng_assume_role.json
}


data "aws_iam_policy_document" "ops_eng_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::880656497252:role/assume_cloud_platform_route53_read_role"]
    }
  }
}

data "aws_iam_policy_document" "ops_eng_route53_readonly" {
  statement {
    actions = [
      "route53:Get*",
      "route53:List*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ops_eng_route53_readonly" {
  name        = "ops-eng-route53-readonly-access"
  description = "Allow read-only access to Route53 for Operations Engineering Account"
  policy      = data.aws_iam_policy_document.ops_eng_route53_readonly.json
}

resource "aws_iam_policy_attachment" "ops_eng_route53_readonly" {
  name       = "ops-eng-route53-readonly-access-attachment"
  policy_arn = aws_iam_policy.ops_eng_route53_readonly.arn
  roles      = [aws_iam_role.ops_eng_route53_readonly.name]
}