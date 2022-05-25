locals {
  live_domain = "cloud-platform-live"

  allowed_live_1_ips = {
    "35.178.209.113/32" = "live-1-a"
    "35.177.252.54/32"  = "live-1-b"
    "3.8.51.207/32"     = "live-1-c"
  }

  audit_domain = "cloud-platform-audit"

  audit_live_domain = "cloud-platform-audit-live"

  allowed_audit_1_ips = local.allowed_live_1_ips
  # for tests, use something like merge(local.allowed_live_1_ips, { "88.98.227.149" = "raz" })

  allowed_audit_live_ips = local.allowed_live_1_ips

  test_domain = "cloud-platform-test"

  allowed_test_ips = {
    "3.10.134.18/32"     = "?"
    "3.10.182.216/32"    = "?"
    "3.10.148.25/32"     = "?"
    "35.178.209.113/32"  = "?"
    "35.177.252.54/32"   = "?"
    "3.8.51.207/32"      = "?"
    "88.98.227.149/32"   = "?"
    "82.46.130.162/32"   = "?"
    "35.178.31.199/32"   = "?"
    "3.9.196.241/32"     = "?"
    "3.10.159.29/32"     = "?"
    "213.121.161.124/32" = "102PFWifi"
    "81.134.202.29/32"   = "MoJDigital"
  }
}

data "aws_region" "moj-dsd" {
}

data "aws_caller_identity" "moj-dsd" {
}

data "aws_region" "moj-cp" {
  provider = aws.cloud-platform
}

data "aws_caller_identity" "moj-cp" {
  provider = aws.cloud-platform
}

data "aws_iam_policy_document" "live_1" {
  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.moj-cp.name}:${data.aws_caller_identity.moj-cp.account_id}:domain/${local.live_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      values = keys(local.allowed_live_1_ips)
    }
  }
}

resource "aws_elasticsearch_domain" "live_1" {
  domain_name           = local.live_domain
  provider              = aws.cloud-platform
  elasticsearch_version = "7.4"

  cluster_config {
    instance_type            = "r5.4xlarge.elasticsearch"
    instance_count           = "15"
    dedicated_master_enabled = true
    dedicated_master_type    = "m4.large.elasticsearch"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true

    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "1536"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = data.aws_iam_policy_document.live_1.json

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  log_publishing_options {
    cloudwatch_log_group_arn = ""
    enabled                  = false
    log_type                 = "ES_APPLICATION_LOGS"
  }


  tags = {
    Domain = local.live_domain
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
      "arn:aws:es:${data.aws_region.moj-cp.name}:${data.aws_caller_identity.moj-cp.account_id}:domain/${local.audit_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      values = keys(local.allowed_audit_1_ips)
    }
  }
}

data "aws_iam_policy_document" "audit_live" {
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
      "es:ListElasticsearchVersions"
    ]

    resources = [
      "arn:aws:es:${data.aws_region.moj-cp.name}:${data.aws_caller_identity.moj-cp.account_id}:domain/${local.audit_live_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = keys(local.allowed_audit_live_ips)
    }
  }
}

# audit cluster for live-1
resource "aws_elasticsearch_domain" "audit_1" {
  domain_name           = local.audit_domain
  provider              = aws.cloud-platform
  elasticsearch_version = "7.10"

  cluster_config {
    instance_type            = "m4.2xlarge.elasticsearch"
    instance_count           = "8"
    dedicated_master_enabled = true
    dedicated_master_type    = "r5.large.elasticsearch"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "1536"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "override_main_response_version"         = "true"
  }

  access_policies = data.aws_iam_policy_document.audit_1.json

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = local.audit_domain
  }
  log_publishing_options {
    cloudwatch_log_group_arn = "arn:aws:logs:${data.aws_region.moj-cp.name}:${data.aws_caller_identity.moj-cp.account_id}:log-group:/aws/OpenSearchService/domains/${local.audit_domain}/application-logs"
    enabled                  = true
    log_type                 = "ES_APPLICATION_LOGS"
  }
}

# audit cluster for live
resource "aws_elasticsearch_domain" "audit_live" {
  domain_name           = local.audit_live_domain
  provider              = aws.cloud-platform
  elasticsearch_version = "OpenSearch_1.0"

  cluster_config {
    instance_type            = "m5.2xlarge.elasticsearch"
    instance_count           = "8"
    dedicated_master_enabled = true
    dedicated_master_type    = "r5.large.elasticsearch"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp2"
    volume_size = "1536"
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "override_main_response_version"         = "false"
  }

  access_policies = data.aws_iam_policy_document.audit_live.json

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags = {
    Domain = local.audit_domain
  }

  log_publishing_options {
    cloudwatch_log_group_arn = "arn:aws:logs:${data.aws_region.moj-cp.name}:${data.aws_caller_identity.moj-cp.account_id}:log-group:/aws/OpenSearchService/domains/${local.audit_live_domain}/application-logs"
    enabled                  = true
    log_type                 = "ES_APPLICATION_LOGS"
  }
}


data "aws_iam_policy_document" "test" {
  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.moj-cp.name}:${data.aws_caller_identity.moj-cp.account_id}:domain/${local.test_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
      # force an interpolation expression to be interpreted as a list by wrapping it
      # in an extra set of list brackets. That form was supported for compatibility in
      # v0.11, but is no longer supported in Terraform v0.12.
      #
      # If the expression in the following list itself returns a list, remove the
      # brackets to avoid interpretation as a list of lists. If the expression
      # returns a single list item then leave it as-is and remove this TODO comment.
      values = keys(merge(local.allowed_test_ips))
    }
  }
}

# Uncomment this, if you need to create a test ES.
# resource "aws_elasticsearch_domain" "test" {
#   domain_name           = "cloud-platform-test"
#   provider              = aws.cloud-platform
#   elasticsearch_version = "7.4"

#   cluster_config {
#     instance_type  = "r5.large.elasticsearch"
#     instance_count = "1"
#   }

#   ebs_options {
#     ebs_enabled = "true"
#     volume_type = "gp2"
#     volume_size = "500"
#   }

#   access_policies = data.aws_iam_policy_document.test.json

#   log_publishing_options {
#     cloudwatch_log_group_arn = ""
#     enabled                  = false
#     log_type                 = "ES_APPLICATION_LOGS"
#   }
# }

module "live_elasticsearch_monitoring" {
  source  = "dubiety/elasticsearch-cloudwatch-sns-alarms/aws"
  version = "2.1.0"

  alarm_name_prefix = "cloud-platform-live-"
  domain_name       = local.live_domain
  create_sns_topic  = false
  sns_topic         = data.terraform_remote_state.account.outputs.slack_sns_topic

  alarm_cluster_status_is_yellow_periods = 10
}

module "audit_elasticsearch_monitoring" {
  source  = "dubiety/elasticsearch-cloudwatch-sns-alarms/aws"
  version = "2.1.0"

  alarm_name_prefix = "cloud-platform-audit-"
  domain_name       = local.audit_domain
  create_sns_topic  = false
  sns_topic         = data.terraform_remote_state.account.outputs.slack_sns_topic
}
