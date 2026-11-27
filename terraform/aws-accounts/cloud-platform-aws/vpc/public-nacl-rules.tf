/// The following are placeholders to create network ACL deny rules for the public subnet to stop traffic to and from the EKS cluster boundary.
/// Please view the runbook for more information: https://runbooks.cloud-platform.service.justice.gov.uk/block-public-ip-address.html
variable "blocked_ip" {
  description = "The IP address to block in the public subnet network ACL"
  type        = map(string)
  default = {
    "159.26.119.67/32"  = "159.26.119.67/32"
    "18.168.1.44/32"    = "18.168.1.44/32"
    "52.56.214.195/32"  = "52.56.214.195/32"
    "13.42.111.82/32"   = "13.42.111.82/32"
    "35.177.145.184/32" = "35.177.145.184/32"
    "13.230.30.133/32"  = "13.230.30.133/32"
  }
}

resource "aws_network_acl_rule" "deny_inbound_1" {
  for_each       = var.blocked_ip
  network_acl_id = module.vpc.public_network_acl_id
  rule_number    = 10 + index(keys(var.blocked_ip), each.key) + 1
  egress         = false
  protocol       = "-1" # -1 means all protocols
  rule_action    = "deny"
  cidr_block     = each.value
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "deny_outbound_1" {
  for_each       = var.blocked_ip
  network_acl_id = module.vpc.public_network_acl_id
  rule_number    = 10 + index(keys(var.blocked_ip), each.key) + 1
  egress         = true
  protocol       = "-1" # -1 means all protocols
  rule_action    = "deny"
  cidr_block     = each.value
  from_port      = 0
  to_port        = 0
}
