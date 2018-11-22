terraform {
  backend "s3" {
    bucket = "cloud-platform-kibana"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "terraform_remote_state" "global" {
  backend = "s3"

  config {
    bucket = "cloud-platform-kibana"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_elasticsearch_domain" "test" {
  domain_name           = "${local.test_domain}"
  elasticsearch_version = "6.2"

  cluster_config {
    instance_type  = "m4.large.elasticsearch"
    instance_count = "3"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "150"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.test_domain}/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": ${jsonencode(keys(local.allowed_test_ips))}
        }
      }
    }
  ]
}
CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${local.test_domain}"
  }
}

resource "aws_elasticsearch_domain" "live" {
  domain_name           = "${local.live_domain}"
  elasticsearch_version = "6.2"

  cluster_config {
    instance_type  = "m4.large.elasticsearch"
    instance_count = "3"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "320"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.live_domain}/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": ${jsonencode(keys(local.allowed_live_ips))}
        }
      }
    }
  ]
}
CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${local.live_domain}"
  }
}

resource "aws_elasticsearch_domain" "audit" {
  domain_name           = "${local.audit_domain}"
  elasticsearch_version = "6.2"

  cluster_config {
    instance_type  = "m4.large.elasticsearch"
    instance_count = "2"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "320"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action":[ "es:AddTags",
                "es:ESHttpHead",
                "es:DescribeElasticsearchDomain",
                "es:ESHttpPost",
                "es:ESHttpGet",
                "es:ESHttpPut",
                "es:DescribeElasticsearchDomainConfig",
                "es:ListTags",
                "es:DescribeElasticsearchDomains",
                "es:ListDomainNames",
                "es:ListElasticsearchInstanceTypes",
                "es:DescribeElasticsearchInstanceTypeLimits",
                "es:ListElasticsearchVersions"
      ],
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.audit_domain}/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": ${jsonencode(keys(local.allowed_audit_ips))}
        }
      }
    }
  ]
}
CONFIG

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${local.audit_domain}"
  }
}
