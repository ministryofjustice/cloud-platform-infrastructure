provider "elasticsearch" {
  url         = "https://${aws_elasticsearch_domain.live_1.endpoint}"
}

locals {
  live_domain = "cloud-platform-live"

  allowed_live_1_ips = {
    "35.177.252.54/32"  = "live-1-b"
    "35.178.209.113/32" = "live-1-a"
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

data "aws_region" "moj-cp" {
  provider = aws.cloud-platform
}

data "aws_caller_identity" "moj-cp" {
  provider = aws.cloud-platform
}

data "aws_iam_policy_document" "live_1" {
  statement {
    actions = [
      "es:Describe*",
      "es:List*",
      "es:ESHttpGet",
      "es:ESHttpHead",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpPatch"
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

      values = keys(local.allowed_live_1_ips)
    }
  }
}

resource "aws_elasticsearch_domain" "live_1" {
  domain_name           = local.live_domain
  provider              = aws.cloud-platform
  elasticsearch_version = "7.10"

  cluster_config {
    instance_type            = "r6g.4xlarge.elasticsearch"
    instance_count           = "6"
    dedicated_master_enabled = true
    dedicated_master_type    = "m6g.xlarge.elasticsearch"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true
    zone_awareness_config {
      availability_zone_count = 3
    }
    warm_count   = 3
    warm_enabled = true
    warm_type    = "ultrawarm1.medium.elasticsearch"
    cold_storage_options {
      enabled = true
    }
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp3"
    volume_size = "1536"
    iops        = 4608
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
    "indices.query.bool.max_clause_count"    = 3000
    "override_main_response_version"         = "true"
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

resource "elasticsearch_opensearch_ism_policy" "ism-policy" {
  policy_id = "hot-warm-cold-delete"
  body      = data.template_file.ism_policy.rendered
}

data "template_file" "ism_policy" {
  template = templatefile("${path.module}/resources/opensearch/ism-policy.json.tpl", {

    timestamp_field   = var.timestamp_field
    warm_transition   = var.warm_transition
    cold_transition   = var.cold_transition
    delete_transition = var.delete_transition
    index_pattern     = jsonencode(var.index_pattern)
  })
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
    instance_type            = "m6g.xlarge.elasticsearch"
    instance_count           = "2"
    dedicated_master_enabled = true
    dedicated_master_type    = "r6g.large.elasticsearch"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true
    warm_count               = 2
    warm_enabled             = true
    warm_type                = "ultrawarm1.medium.elasticsearch"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp3"
    volume_size = "1536"
    iops        = 4608
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
    instance_type            = "m6g.xlarge.elasticsearch"
    instance_count           = "2"
    dedicated_master_enabled = true
    dedicated_master_type    = "r6g.large.elasticsearch"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true
    warm_count               = 2
    warm_enabled             = true
    warm_type                = "ultrawarm1.medium.elasticsearch"
  }

  ebs_options {
    ebs_enabled = "true"
    volume_type = "gp3"
    volume_size = "1536"
    iops        = 4608
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

      values = keys(merge(local.allowed_test_ips))
    }
  }
}

# If you need to create a test ES, see https://github.com/ministryofjustice/cloud-platform-terraform-elasticsearch/tree/main/example

module "live_elasticsearch_monitoring" {
  source  = "dubiety/elasticsearch-cloudwatch-sns-alarms/aws"
  version = "3.0.3"

  alarm_name_prefix = "cloud-platform-live-"
  domain_name       = local.live_domain
  create_sns_topic  = false
  sns_topic         = data.terraform_remote_state.account.outputs.slack_sns_topic

  alarm_cluster_status_is_yellow_periods = 10
}

module "audit_elasticsearch_monitoring" {
  source  = "dubiety/elasticsearch-cloudwatch-sns-alarms/aws"
  version = "3.0.3"

  alarm_name_prefix = "cloud-platform-audit-"
  domain_name       = local.audit_domain
  create_sns_topic  = false
  sns_topic         = data.terraform_remote_state.account.outputs.slack_sns_topic
}

module "audit_live_elasticsearch_monitoring" {
  source  = "dubiety/elasticsearch-cloudwatch-sns-alarms/aws"
  version = "3.0.3"

  alarm_name_prefix = "cloud-platform-audit-live-"
  domain_name       = local.audit_live_domain
  create_sns_topic  = false
  sns_topic         = data.terraform_remote_state.account.outputs.slack_sns_topic
}
