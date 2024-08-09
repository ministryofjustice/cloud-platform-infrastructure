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


### Shield Advanced Configuration
# Add ALB resoruce to Shield
data "external" "aws_alb_arns" {
  program = [
    "bash", "-c",
    "aws elbv2 describe-load-balancers --query 'LoadBalancers[?Type==`application`].LoadBalancerArn' --output json | jq -c 'to_entries | map({(\"alb_\" + (.key | tostring)): .value}) | add'"
  ]
}

# resource "aws_shield_protection" "alb_protection" {
#   for_each     = data.external.aws_alb_arns.result
#   name         = each.key
#   resource_arn = each.value
# }

# Add EIP resource to Shield
data "external" "aws_eip_allocation_ids" {
  program = [
    "bash", "-c",
    "aws ec2 describe-addresses --query 'Addresses[*].AllocationId' --output json | jq -c 'to_entries | map({(\"eip_\" + (.key | tostring)): .value}) | add'"
  ]
}

# resource "aws_shield_protection" "eip_protection" {
#   for_each     = data.external.aws_eip_allocation_ids.result
#   name         = each.key
#   resource_arn = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:eip-allocation/${each.value}"
# }

# Add CLB resource to Shield
data "external" "aws_clb_arns" {
  program = [
    "bash", "-c",
    "aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].LoadBalancerName' --output json | jq -c 'to_entries | map({(\"clb_\" + (.key | tostring)): .value}) | add'"
  ]
}

resource "aws_shield_protection" "elb_protection" {
  for_each     = data.external.aws_clb_arns.result
  name         = each.key
  resource_arn = "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/${each.value}"
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


# resource "aws_wafv2_web_acl" "main" {
#   #checkov:skip=CKV_AWS_192: Log4J handled by remediation rule
#   #checkov:skip=CKV2_AWS_31:  Logging not required at this time
#   name  = data.external.shield_waf.result["name"]
#   scope = "REGIONAL"
#   default_action {
#     allow {}
#   }
#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = data.external.shield_waf.result["name"]
#     sampled_requests_enabled   = false
#   }
#   dynamic "rule" {
#     for_each = var.waf_acl_rules
#     content {
#       name     = rule.value["name"]
#       priority = rule.value["priority"]
#       dynamic "action" {
#         for_each = rule.value["action"] == "count" ? [1] : []
#         content {
#           count {}
#         }
#       }
#       dynamic "action" {
#         for_each = rule.value["action"] == "block" ? [1] : []
#         content {
#           block {}
#         }
#       }
#       statement {
#         rate_based_statement {
#           aggregate_key_type    = "IP"
#           evaluation_window_sec = 300
#           limit                 = rule.value["threshold"]
#         }
#       }

#       visibility_config {
#         cloudwatch_metrics_enabled = true
#         metric_name                = rule.value["action"]
#         sampled_requests_enabled   = true
#       }
#     }
#   }
# }