# Create IAM Role for AWS Shield Advanced SRT (Shield Response Team) support role
resource "aws_iam_role" "srt_role" {
  name = "AWSSRTSupport"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "drt.shield.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "shield_response_team_role_policy_attachment" {
  role       = aws_iam_role.srt_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSShieldDRTAccessPolicy"
}

resource "aws_shield_drt_access_role_arn_association" "main" {
  role_arn = aws_iam_role.srt_role.arn
}

# Assume CP AWS Account is added to local.shield_advanced_auto_remediate.account in below link
# https://github.com/ministryofjustice/aws-root-account/blob/4c99410e80d546b01cc9cc249822fc294ad77bfc/organisation-security/terraform/locals.tf#L120
# Shield Advanced Configuration
data "external" "shield_protections" {
  program = [
    "bash", "-c",
    "aws shield list-protections --output json | jq -c '.Protections | map({(.Id): (. | tostring)}) | add'"
  ]
}
data "external" "shield_waf" {
  program = [
    "bash", "-c",
    "aws wafv2 list-web-acls --scope REGIONAL --output json | jq -c '{arn: .WebACLs[] | select(.Name | contains(\"FMManagedWebACL\")) | .ARN, name: .WebACLs[] | select(.Name | contains(\"FMManagedWebACL\")) | .Name}'"
  ]
}


locals {
  shield_protections_json = {
    for k, v in data.external.shield_protections.result : k => v
    if !can(regex("eip", jsondecode(v)["ResourceArn"]))
  }

  shield_protections = {
    for k, v in local.shield_protections_json : k => jsondecode(v)
  }
}


# resource "aws_shield_application_layer_automatic_response" "this" {
#   for_each     = { for k, v in var.resources : k => v if lookup(v, "protection", null) != null }
#   resource_arn = each.value["arn"]
#   action       = upper(each.value["action"])
# }

resource "aws_wafv2_web_acl_association" "this" {
  for_each     = local.shield_protections
  resource_arn = each.value["ResourceArn"]
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}


# Create ACL and we do not need to import the inherited empty rule
resource "aws_wafv2_web_acl" "main" {
  name  = "acl"
  scope = "REGIONAL"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = data.external.shield_waf.result["name"]
    sampled_requests_enabled   = false
  }
  dynamic "rule" {
    for_each = var.waf_acl_rules
    content {
      name     = rule.value["name"]
      priority = rule.value["priority"]
      dynamic "action" {
        for_each = rule.value["action"] == "count" ? [1] : []
        content {
          count {}
        }
      }
      dynamic "action" {
        for_each = rule.value["action"] == "block" ? [1] : []
        content {
          block {}
        }
      }
      statement {
        rate_based_statement {
          aggregate_key_type    = "IP"
          evaluation_window_sec = 300
          limit                 = rule.value["threshold"]
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value["action"]
        sampled_requests_enabled   = true
      }
    }
  }
}



# # Protected resource group
# resource "aws_shield_protection_group" "eip" {
#   protection_group_id = "elastic-ip-addresses"
#   aggregation         = "SUM"
#   pattern             = "BY_RESOURCE_TYPE"
#   resource_type       = "ELASTIC_IP_ALLOCATION"
# }

# resource "aws_shield_protection_group" "alb" {
#   protection_group_id = "application-load-balancers"
#   aggregation         = "MEAN"
#   pattern             = "BY_RESOURCE_TYPE"
#   resource_type       = "APPLICATION_LOAD_BALANCER"
# }