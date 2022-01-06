###########################
# Locals & Data Resources #
###########################

locals {
  vpc_name             = terraform.workspace
  vpc_base_domain_name = "${local.vpc_name}.cloud-platform.service.justice.gov.uk"
  cluster_tags = {
    for name in lookup(var.cluster_names, terraform.workspace, [terraform.workspace]) :
    "kubernetes.io/cluster/${name}" => "shared"
  }
  vpc_tags = merge({
    "kubernetes.io/cluster/${local.vpc_name}" = "shared"
  }, local.cluster_tags)

  # adapted from https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/v3.11.0/examples/network-acls/main.tf
  network_acls = {
    block_inbound = [
      {
        rule_number = 100
        rule_action = "deny"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_block  = "82.132.219.135/32"
      },
    ]
    block_outbound = [
      {
        rule_number = 100
        rule_action = "deny"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_block  = "82.132.219.135/32"
      },
    ]
    public_inbound = [
      {
        rule_number = 900
        rule_action = "allow"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        rule_number = 910
        rule_action = "allow"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
    ]
    public_outbound = [
      {
        rule_number = 900
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_block  = "0.0.0.0/0"
      },
    ]
  }

}
