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
  subnets = { for idx, subnet in aws_subnet.firewall : "subnet${idx + 1}" =>
    {
      subnet_id       = subnet.id
      ip_address_type = "IPV4"
    }
  }
  vpc = module.vpc.vpc_id

  firewall_endpoints = {
    for state in module.cloud-platform-firewall.status[0].sync_states :
    state.availability_zone => state.attachment[0].endpoint_id
  }  
}

module "cloud-platform-firewall" {
  source              = "terraform-aws-modules/network-firewall/aws//modules/firewall"
  version             = "1.0.2"
  description         = "Network firewall positioned to secure flows between Cloud Platform VPC and the Internet"
  firewall_policy_arn = module.cloud-platform-firewall-policy.arn
  name                = "${local.vpc_name}-firewall"
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
  description = "Firewall policy intended for cloud-platform-egress-firewall"
  name        = "${local.vpc_name}-firewall-policy"

  stateless_default_actions          = ["aws:forward_to_sfe"]
  stateless_fragment_default_actions = ["aws:drop"]

  stateful_engine_options = {
    rule_order = "STRICT_ORDER"
  }

  stateful_rule_group_reference = [
    { priority = 1
    resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/AttackInfrastructureStrictOrder" },
    { priority = 2
    resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/MalwareDomainsStrictOrder" },
    { priority = 3
    resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/BotNetCommandAndControlDomainsStrictOrder" },
    { priority = 10
    resource_arn = module.cloud-platform-firewall-rule-group.arn }
  ]
}

module "cloud-platform-firewall-rule-group" {
  source      = "terraform-aws-modules/network-firewall/aws//modules/rule-group"
  version     = "1.0.2"
  capacity    = 5000
  description = "Stateful rule group configured to control traffic between Cloud Platform and the Internet."
  name        = "${local.vpc_name}-firewall-stateful-rules"
  type        = "STATEFUL"

  rule_group = {
    stateful_rule_options = {
      rule_order = "STRICT_ORDER"
    }
    rules_source = {
      stateful_rule = local.stateful_rules
    }
    rule_variables = {
      ip_sets = [
        { key    = "HOME_NET"
          ip_set = { definition = ["0.0.0.0/0"] }
        },
        { key    = "EXTERNAL_NET"
          ip_set = { definition = ["0.0.0.0/0"] }
        }
      ]
    }
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name_prefix       = "${local.vpc_name}-firewall-logs"
  retention_in_days = 7
}

resource "aws_subnet" "firewall" {
  count = 3

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 12, count.index + 208)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge({
    Name                              = "${local.vpc_name}-firewall-${var.availability_zones[count.index]}"
    SubnetType                        = "Firewall"
    Terraform                         = "true"
    Cluster                           = local.vpc_name
    Domain                            = local.vpc_base_domain_name
  }, local.cluster_tags)
}

# Create route tables for each firewall subnet
resource "aws_route_table" "firewall" {
  count = 3

  vpc_id = module.vpc.vpc_id

  tags = merge({
    Name       = "${local.vpc_name}-firewall-${var.availability_zones[count.index]}"
    SubnetType = "Firewall"
    Terraform  = "true"
    Cluster    = local.vpc_name
    Domain     = local.vpc_base_domain_name
  }, local.cluster_tags)
}

# Associate each route table with its corresponding firewall subnet
resource "aws_route_table_association" "firewall" {
  count = 3

  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall[count.index].id
}

# Route default traffic to NAT Gateways (one per AZ since one_nat_gateway_per_az = true)
resource "aws_route" "firewall_to_nat" {
  count = 3

  route_table_id         = aws_route_table.firewall[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.vpc.natgw_ids[count.index]
}

resource "aws_route" "private_subnets_to_firewall" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoints[var.availability_zones[count.index]]

  # Ensure vpc and firewall is created before adding routes
  depends_on = [
    module.cloud-platform-firewall,
    module.vpc
  ]
}

# The following add routes from the public subnet to corresponding AZ firewall endpoints
# create_multiple_public_route_tables needs to be `true` in the vpc module

resource "aws_route" "public_subnets_to_private" {
  count = length(module.vpc.public_route_table_ids)

  route_table_id         = module.vpc.public_route_table_ids[count.index]
  destination_cidr_block = module.vpc.private_subnets_cidr_blocks[count.index]
  vpc_endpoint_id        = local.firewall_endpoints[var.availability_zones[count.index]]

  # Ensure vpc and firewall is created before adding routes
  depends_on = [
    module.cloud-platform-firewall,
    module.vpc
  ]
}

resource "aws_route" "public_subnets_to_eks_private" {
  count = length(module.vpc.public_route_table_ids)

  route_table_id         = module.vpc.public_route_table_ids[count.index]
  destination_cidr_block = aws_subnet.eks_private[count.index].cidr_block
  vpc_endpoint_id        = local.firewall_endpoints[var.availability_zones[count.index]]

  # Ensure vpc and firewall is created before adding routes
  depends_on = [
    module.cloud-platform-firewall,
    module.vpc,
    aws_subnet.eks_private
  ]
}

# Route from private subnets to public subnets via firewall endpoints
resource "aws_route" "private_subnets_to_public" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = module.vpc.public_subnets_cidr_blocks[count.index]
  vpc_endpoint_id        = local.firewall_endpoints[var.availability_zones[count.index]]

  # Ensure vpc and firewall is created before adding routes
  depends_on = [
    module.cloud-platform-firewall,
    module.vpc
  ]
}