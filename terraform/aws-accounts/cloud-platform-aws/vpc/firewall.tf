locals {
  firewall_rules_string = fileexists("./firewall_rules.rules") ? file("./firewall_rules.rules") : ""

  subnets = { for idx, subnet in aws_subnet.firewall_private : "subnet${idx + 1}" =>
    {
      subnet_id       = subnet.id
      ip_address_type = "IPV4"
    }
  }
  vpc = module.vpc.vpc_id
}

module "cloud-platform-firewall" {
  source              = "terraform-aws-modules/network-firewall/aws//modules/firewall"
  version             = "2.0.2"
  description         = "Network firewall positioned to secure flows between Cloud Platform VPC and the Internet"
  firewall_policy_arn = module.cloud-platform-firewall-policy.arn
  name                = "${local.vpc_name}-firewall"
  subnet_mapping      = local.subnets
  vpc_id              = local.vpc
  delete_protection   = false

  # Logging configuration
  create_logging_configuration = true
  logging_configuration_destination_config = [
    {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.logs.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    },
    {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.logs.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  ]
}

module "cloud-platform-firewall-policy" {
  source      = "terraform-aws-modules/network-firewall/aws//modules/policy"
  version     = "2.0.2"
  description = "Firewall policy intended for cloud-platform-egress-firewall"
  name        = "${local.vpc_name}-firewall-policy"

  stateless_default_actions          = ["aws:forward_to_sfe"]
  stateless_fragment_default_actions = ["aws:drop"]

  stateful_engine_options = {
    rule_order = "STRICT_ORDER"
  }

  stateful_rule_group_reference = [
    {
      priority     = 1
      resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/AttackInfrastructureStrictOrder"
      override = {
        action = "DROP_TO_ALERT"
      }
    },
    {
      priority     = 2
      resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/MalwareDomainsStrictOrder"
      override = {
        action = "DROP_TO_ALERT"
      }
    },
    {
      priority     = 3
      resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/BotNetCommandAndControlDomainsStrictOrder"
      override = {
        action = "DROP_TO_ALERT"
      }
    },
    {
      priority     = 10
      resource_arn = module.cloud-platform-firewall-rule-group.arn
    }
  ]
}

module "cloud-platform-firewall-rule-group" {
  source      = "terraform-aws-modules/network-firewall/aws//modules/rule-group"
  version     = "2.0.2"
  capacity    = 5000
  description = "Stateful rule group configured to control traffic between Cloud Platform and the Internet."
  name        = "${local.vpc_name}-firewall-stateful-rules"
  type        = "STATEFUL"

  rule_group = {
    stateful_rule_options = {
      rule_order = "STRICT_ORDER"
    }
    rules_source = {
      rules_string = local.firewall_rules_string
    }
    rule_variables = {
      ip_sets = [
        { key    = "HOME_NET"
          ip_set = { definition = [module.vpc.vpc_cidr_block] }
        }
      ]
    }
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name_prefix       = "${local.vpc_name}-firewall-logs"
  retention_in_days = 7
}
