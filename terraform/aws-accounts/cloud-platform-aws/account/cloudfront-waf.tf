# This is a very specific AWS WAF implemention for use with CloudFront only
# Users with an ingress must only utilise ModSecurity or the WAF-enabled centralised ingress
# This WAF IPSet, rule, and corresponding WAF ACL is very specific to Prisoner Content Hub
# who stream videos from an S3 bucket which is limited to access within a prison estate
# Using AWS WAF is/was the only way to IP allowlist with CloudFront (as at 2023-10-12).
# We should explore alternatives as they become available.

# resource "aws_ssm_parameter" "prisoner_content_hub_production" {
#   name  = "/prisoner-content-hub-production/ip-allow-list"
#   type  = "String"
#   value = "bar"
# }

# resource "aws_ssm_parameter" "prisoner_content_hub_staging" {
#   name  = "/prisoner-content-hub-staging/ip-allow-list"
#   type  = "String"
#   value = "bar"
# }

# resource "aws_ssm_parameter" "prisoner_content_hub_development" {
#   name  = "/prisoner-content-hub-development/ip-allow-list"
#   type  = "String"
#   value = "bar"
# }

data "aws_ssm_parameter" "test" {
  name = "/prisoner-content-hub-test/ip-allow-list"
}

resource "aws_wafv2_ip_set" "prisoner_content_hub" {
  provider = aws.northvirginia

  name               = "prisoner-content-hub-production"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses = toset([
    for k, v in tomap(jsondecode(nonsensitive(data.aws_ssm_parameter.test.value))) :
    (length(split("/", v)) > 1) ? v : "${v}/32" # when we update to terraform 1.5.0, we can use strcontains()
  ])
}

resource "aws_wafv2_web_acl" "prisoner_content_hub" {
  provider = aws.northvirginia

  name  = "prisoner-content-hub-production"
  scope = "CLOUDFRONT"

  default_action {
    allow {
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "prisoner-content-hub-production"
  }

  rule {
    name     = "ip_block"
    priority = 1

    action {
      block {
        custom_response {
          response_code = 403
        }
      }
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.prisoner_content_hub.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "prisoner-content-hub-production-blocked-ips"
      sampled_requests_enabled   = true
    }
  }
}
