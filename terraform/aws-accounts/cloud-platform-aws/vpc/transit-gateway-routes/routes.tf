
locals {
  route_tables = data.terraform_remote_state.cluster-network.outputs.private_route_tables

  cp_tgw_id = data.aws_ec2_transit_gateway.cloud-platform-transit-gateway.id
  ecp_tgw_destination_cidr_blocks = [
    "10.205.10.0/24",
    "10.205.11.0/24",
    "10.205.14.0/24",
    "10.205.15.0/24"
  ]

  pttp_tgw_id = "tgw-026162f1ba39ce704"
  pttp_tgw_destination_cidr_blocks = [
    "10.162.32.0/20", # Delius MIS Dev VPC
    "10.160.32.0/20", # Delius Core Stage VPC
    "10.160.0.0/20",  # Delius Core Pre-Prod VPC
    "10.162.0.0/20",  # Delius Core Test VPC
    "10.160.16.0/20", # Delius Core Prod VPC
    "10.26.0.0/16",   # Mod Platform Dev and Test
    "10.27.0.0/16",   # Mod Platform Pre-Prod and Prod
    "10.202.0.0/20",  # LAA Platform Dev
    "10.203.0.0/20",  # LAA Platform Test
    "10.206.0.0/20",  # LAA Platform UAT
    "10.205.0.0/20",  # LAA Platform Prod
    "10.204.0.0/20",  # LAA Platform Stage
    "10.200.96.0/19", # Analytical Platform Compute Test
    "10.201.128.0/17", # Analytical Platform Compute Production
  ]
}


module "tgw_route" {
  for_each = toset(local.pttp_tgw_destination_cidr_blocks)
  source   = "./modules/tgw-route"

  destination_cidr_block = each.key

  transit_gateway_id = local.pttp_tgw_id
  route_tables       = local.route_tables
}

module "tgw_route_to_ecp" {
  for_each = toset(local.ecp_tgw_destination_cidr_blocks)
  source   = "./modules/tgw-route"

  destination_cidr_block = each.key

  transit_gateway_id = local.cp_tgw_id
  route_tables       = local.route_tables
}
