provider "elasticsearch" {
  url         = "https://${aws_elasticsearch_domain.et_test[0].endpoint}"
  aws_profile = "moj-et"
}


locals {

  test_domain = "cloud-platform-test"

  // Add your IP address to access the cluster using kibana
  allowed_test_ips = {
    "213.121.161.124/32" = "102PFWifi"
    "81.134.202.29/32"   = "MoJDigital"
  }
}

data "aws_iam_policy_document" "et_test" {
  count = 1
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
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.test_domain}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = keys(local.allowed_test_ips)
    }
  }
}

# For logging elastic search on cloudwatch
resource "aws_cloudwatch_log_group" "et_test_log_group" {
  count             = 1
  name              = "/aws/aes/domains/cloud-platform-test/application-logs"
  retention_in_days = 60

  tags = {
    Terraform     = "true"
    application   = "cloud-platform-test"
    business-unit = "Platforms"
    is-production = "true"
    owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
    source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
  }
}

data "aws_iam_policy_document" "elasticsearch_log_publishing_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = [aws_cloudwatch_log_group.et_test_log_group[0].arn]

    principals {
      identifiers = ["es.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "elasticsearch_log_publishing_policy" {
  count           = 1
  policy_document = data.aws_iam_policy_document.elasticsearch_log_publishing_policy_doc.json
  policy_name     = "cloud-platform-test-elasticsearch-log-publishing-policy"
}


resource "aws_elasticsearch_domain" "et_test" {
  count                 = 1
  domain_name           = local.test_domain
  elasticsearch_version = "7.10"

  cluster_config {
    instance_type            = "t3.medium.elasticsearch"
    instance_count           = "7"
    dedicated_master_enabled = true
    dedicated_master_type    = "t3.small.elasticsearch"
    dedicated_master_count   = "3"
    zone_awareness_enabled   = true
    zone_awareness_config {
      availability_zone_count = 3
    }
    warm_count   = 5
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

  access_policies = data.aws_iam_policy_document.et_test[count.index].json

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  log_publishing_options {
    enabled                  = true
    log_type                 = "ES_APPLICATION_LOGS"
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.et_test_log_group[count.index].arn
  }
  auto_tune_options {
    desired_state = "ENABLED"
  }

  tags = {
    Domain = local.test_domain
  }
}

resource "elasticsearch_opensearch_ism_policy" "ism-policy" {
  count     = 1
  policy_id = "hot-warm-cold-delete"
  body = templatefile("${path.module}/resources/opensearch/ism-policy.json.tpl", {
    timestamp_field   = var.timestamp_field
    warm_transition   = var.warm_transition
    cold_transition   = var.cold_transition
    delete_transition = var.delete_transition
    index_pattern     = jsonencode(var.index_pattern)
  })
}

# This is ignored as it provides a convenient IAM policy document for test ElasticSearch clusters
# tflint-ignore: terraform_unused_declarations
data "aws_iam_policy_document" "test" {
  count = 1
  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.test_domain}/*",
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

