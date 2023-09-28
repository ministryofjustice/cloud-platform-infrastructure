# This is a very specific AWS WAF implemention for use with CloudFront only
# Users with an ingress must only utilise ModSecurity or the WAF-enabled centralised ingress
# This WAF IPSet, rule, and corresponding WAF ACL is very specific to Prisoner Content Hub
# who stream videos from an S3 bucket which is limited to access within a prison estate
# Using AWS WAF is the only way to IP allowlist with CloudFront
data "kubernetes_secret_v1" "prisoner_content_hub" {
  metadata {
    name      = "ip-allowlist"
    namespace = "prisoner-content-hub-production"
  }
}

resource "aws_waf_ipset" "prisoner_content_hub" {
  name = "prisoner-content-hub"

  dynamic "ip_set_descriptors" {
    for_each = tomap({
      for k, v in data.kubernetes_secret_v1.prisoner_content_hub.data :
      k => (length(split("/", v)) > 1) ? nonsensitive(v) : "${nonsensitive(v)}/32" # when we update to terraform 1.5.0, we can use strcontains()
    })

    content {
      type  = "IPV4"
      value = sensitive(ip_set_descriptors.value)
    }
  }
}

resource "aws_waf_rule" "prisoner_content_hub" {
  name        = "prisoner_content_hub"
  metric_name = "prisonerContentHub"

  predicates {
    data_id = aws_waf_ipset.prisoner_content_hub.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_web_acl" "prisoner_content_hub" {
  name        = "prisoner_content_hub"
  metric_name = "prisonerContentHub"

  default_action {
    type = "BLOCK"
  }

  rules {
    action {
      type = "ALLOW"
    }

    priority = 1
    rule_id  = aws_waf_rule.prisoner_content_hub.id
    type     = "REGULAR"
  }
}
