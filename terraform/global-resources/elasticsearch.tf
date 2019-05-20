locals {
  live_domain = "cloud-platform-live"

  allowed_live_ips = {
    "52.17.133.167/32"  = "live-0-a"
    "34.247.134.240/32" = "live-0-b"
    "34.251.93.81/32"   = "live-0-c"
  }

  allowed_live_1_ips = {
    "35.178.209.113/32" = "live-1-a"
    "35.177.252.54/32"  = "live-1-b"
    "3.8.51.207/32"     = "live-1-c"
  }

  audit_domain = "cloud-platform-audit"

  allowed_audit_ips = "${local.allowed_live_ips}"

  allowed_audit_1_ips = "${local.allowed_live_1_ips}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "live" {
  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.live_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = [
        "${keys(local.allowed_live_ips)}",
      ]
    }
  }
}

data "aws_iam_policy_document" "live_1" {
  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "arn:aws:es:*:*:domain/${local.live_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = [
        "${keys(local.allowed_live_1_ips)}",
      ]
    }
  }
}

resource "aws_elasticsearch_domain" "live" {
  domain_name           = "${local.live_domain}"
  elasticsearch_version = "6.4"

  cluster_config {
    instance_type            = "m4.xlarge.elasticsearch"
    instance_count           = "4"
    dedicated_master_enabled = true
    dedicated_master_type    = "m4.large.elasticsearch"
    dedicated_master_count   = "3"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "1024"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = "${data.aws_iam_policy_document.live.json}"

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${local.live_domain}"
  }
}

resource "aws_elasticsearch_domain" "live_1" {
  domain_name           = "${local.live_domain}"
  provider              = "aws.cloud-platform"
  elasticsearch_version = "6.4"

  cluster_config {
    instance_type            = "m4.xlarge.elasticsearch"
    instance_count           = "4"
    dedicated_master_enabled = true
    dedicated_master_type    = "m4.large.elasticsearch"
    dedicated_master_count   = "3"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "1024"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = "${data.aws_iam_policy_document.live_1.json}"

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${local.live_domain}"
  }
}

data "aws_iam_policy_document" "audit" {
  statement {
    actions = [
      "es:AddTags",
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
      "es:ListElasticsearchVersions",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.audit_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = [
        "${keys(local.allowed_audit_ips)}",
      ]
    }
  }
}

data "aws_iam_policy_document" "audit_1" {
  statement {
    actions = [
      "es:AddTags",
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
      "es:ListElasticsearchVersions",
    ]

    resources = [
      "arn:aws:es:*:*:domain/${local.audit_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = [
        "${keys(local.allowed_audit_1_ips)}",
      ]
    }
  }
}

resource "aws_elasticsearch_domain" "audit" {
  domain_name           = "${local.audit_domain}"
  elasticsearch_version = "6.4"

  cluster_config {
    instance_type  = "m4.xlarge.elasticsearch"
    instance_count = "3"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "512"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = "${data.aws_iam_policy_document.audit.json}"

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${local.audit_domain}"
  }
}

resource "aws_elasticsearch_domain" "audit_1" {
  domain_name           = "${local.audit_domain}"
  provider              = "aws.cloud-platform"
  elasticsearch_version = "6.4"

  cluster_config {
    instance_type  = "m4.xlarge.elasticsearch"
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

  access_policies = "${data.aws_iam_policy_document.audit_1.json}"

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${local.audit_domain}"
  }
}

resource "aws_elasticsearch_domain" "test" {
  domain_name           = "cloud-platform-test"
  provider              = "aws.cloud-platform"
  elasticsearch_version = "6.5"

  cluster_config {
    instance_type  = "r5.xlarge.elasticsearch"
    instance_count = "1"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "128"
  }

  access_policies = <<TESTPOLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:eu-west-2:754256621582:domain/cloud-platform-test/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": [
            "81.134.202.29",
            "18.130.193.254",
            "18.130.140.174",
            "3.9.1.230",
            "88.98.227.149",
            "35.177.135.226",
            "18.130.212.151",
            "35.178.89.175"
          ]
        }
      }
    }
  ]
}
TESTPOLICY
}
