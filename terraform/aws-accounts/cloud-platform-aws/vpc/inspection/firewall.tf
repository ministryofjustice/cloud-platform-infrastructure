locals {
  raw_rules        = fileexists("./firewall_rules.json") ? jsondecode(file("./firewall_rules.json")) : {}
  sorted_rule_keys = sort(keys(local.raw_rules))
  stateful_rules = [for idx, key in local.sorted_rule_keys : {
    action = local.raw_rules[key].action
    header = {
      destination      = local.raw_rules[key].destination_ip
      destination_port = local.raw_rules[key].destination_port
      direction        = "ANY"
      protocol         = local.raw_rules[key].protocol
      source           = local.raw_rules[key].source_ip
      source_port      = "ANY"
    }
    rule_option = [
      {
        keyword  = "sid"
        settings = [tostring(idx + 1)]
      }
    ]
  }]
  subnets = { for idx, subnet in module.vpc.private_subnets : "subnet${idx + 1}" =>
    {
      subnet_id       = subnet
      ip_address_type = "IPV4"
    }
  }
  vpc = module.vpc.vpc_id
}

module "cloud-platform-firewall" {
  source              = "terraform-aws-modules/network-firewall/aws//modules/firewall"
  version             = "1.0.2"
  description         = "Network firewall positioned to secure flows between Cloud Platform and the MOJ internal network."
  firewall_policy_arn = module.cloud-platform-firewall-policy.arn
  name                = "cloud-platform-firewall"
  subnet_mapping      = local.subnets
  vpc_id              = local.vpc

  # Logging configuration
  create_logging_configuration = true
  logging_configuration_destination_config = [
    {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.logs.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  ]
}

module "cloud-platform-firewall-policy" {
  source      = "terraform-aws-modules/network-firewall/aws//modules/policy"
  version     = "1.0.2"
  description = "Firewall policy intended for cloud-platform-firewall"
  name        = "cloud-platform-firewall-policy"

  stateless_default_actions          = ["aws:forward_to_sfe"]
  stateless_fragment_default_actions = ["aws:drop"]

  stateful_rule_group_reference = [{
    resource_arn = module.cloud-platform-firewall-rule-group.arn
  }]
}

module "cloud-platform-firewall-rule-group" {
  source      = "terraform-aws-modules/network-firewall/aws//modules/rule-group"
  version     = "1.0.2"
  capacity    = 30000
  description = "Stateful rule group configured to control traffic between Cloud Platform and the MOJ internal network."
  name        = "cloud-platform-firewall-stateful-rules"
  type        = "STATEFUL"

  rule_group = {
    stateful_rule_options = {
      rule_order = "DEFAULT_ACTION_ORDER"
    }
    rules_source = {
      stateful_rule = local.stateful_rules
    }
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name_prefix       = "cloud-platform-firewall-logs"
  retention_in_days = 7
}
