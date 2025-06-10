locals {
  tgw_route_table_names = toset(["external", "inspection", "internal"])
}

module "cloud-platform-transit-gateway" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "2.13.0"

  name        = "cloud-platform-transit-gateway"
  description = "Transit Gateway connecting the MOJ Cloud Platform with internal AWS and on-premise environments."

  create_tgw_routes                      = false
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  share_tgw                              = false
  vpc_attachments                        = {}
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = local.tgw_route_table_names
  transit_gateway_id = module.cloud-platform-transit-gateway.ec2_transit_gateway_id
}
