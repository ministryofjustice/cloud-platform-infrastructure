/// The following are placeholders to create network ACL deny rules for the public subnet to stop traffic to and from the EKS cluster boundary.
/// Please view the runbook for more information: https://runbooks.cloud-platform.service.justice.gov.uk/block-public-ip-address.html

# resource "aws_network_acl_rule" "deny_inbound_1" {
#   network_acl_id = module.vpc.public_network_acl_id
#   rule_number    = 10
#   egress         = false
#   protocol       = "-1" # -1 means all protocols
#   rule_action    = "deny"
#   cidr_block     = "##.##.##.##/32"
#   from_port      = 0
#   to_port        = 0
# }

# resource "aws_network_acl_rule" "deny_outbound_1" {
#   network_acl_id = module.vpc.public_network_acl_id
#   rule_number    = 10
#   egress         = true
#   protocol       = "-1" # -1 means all protocols
#   rule_action    = "deny"
#   cidr_block     = "##.##.##.##/32"
#   from_port      = 0
#   to_port        = 0
# }