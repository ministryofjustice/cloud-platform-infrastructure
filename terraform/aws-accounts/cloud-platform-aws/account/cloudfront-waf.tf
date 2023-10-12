# This is a very specific AWS WAF implemention for use with CloudFront only
# Users with an ingress must only utilise ModSecurity or the WAF-enabled centralised ingress
# This WAF IPSet, rule, and corresponding WAF ACL is very specific to Prisoner Content Hub
# who stream videos from an S3 bucket which is limited to access within a prison estate
# Using AWS WAF is/was the only way to IP allowlist with CloudFront (as at 2023-10-12).
# We should explore alternatives as they become available.

locals {
  prisoner_content_hub_environments = toset(["production", "staging", "development"])
}

resource "aws_ssm_parameter" "prisoner_content_hub" {
  for_each = local.prisoner_content_hub_environments

  name  = "/prisoner-content-hub-${each.value}/ip-allow-list"
  type  = "String"
  value = "{}"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_wafv2_ip_set" "prisoner_content_hub" {
  for_each = local.prisoner_content_hub_environments
  provider = aws.northvirginia

  name               = "prisoner-content-hub-${each.value}"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses = toset([
    for k, v in tomap(jsondecode(nonsensitive(aws_ssm_parameter.prisoner_content_hub[each.value].value))) :
    (length(split("/", v)) > 1) ? v : "${v}/32" # when we update to terraform 1.5.0, we can use strcontains()
  ])
}

resource "aws_wafv2_web_acl" "prisoner_content_hub" {
  for_each = local.prisoner_content_hub_environments
  provider = aws.northvirginia

  name  = "prisoner-content-hub-${each.value}"
  scope = "CLOUDFRONT"

  default_action {
    block {
      custom_response {
        response_code = 403
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "prisoner-content-hub-${each.value}"
  }

  rule {
    name     = "ip_allow"
    priority = 0

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.prisoner_content_hub[each.value].arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "prisoner-content-hub-${each.value}-allowed-ips"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_ssm_parameter" "prisoner_content_hub_web_acl_arn" {
  for_each = local.prisoner_content_hub_environments

  name  = "/prisoner-content-hub-${each.value}/web-acl-arn"
  type  = "String"
  value = aws_wafv2_web_acl.prisoner_content_hub[each.value].arn
}