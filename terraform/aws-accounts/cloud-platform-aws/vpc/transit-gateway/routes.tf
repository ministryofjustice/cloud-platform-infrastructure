
locals {
  route_tables = data.terraform_remote_state.cluster-network.outputs.private_route_tables
  route_tables_live_2 = data.terraform_remote_state.cluster-network-live-2.outputs.private_route_tables

  pttp_tgw_id = "tgw-026162f1ba39ce704"
  
  // Add destination CIDR blocks to connect from live-1 cluster
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
    "10.204.0.0/20"   # LAA Platform Stage
  ]

  // Add destination CIDR blocks to connect from live-2 cluster 
  	pttp_tgw_live_2_destination_cidr_blocks = [

  ]
}


module "tgw_route" {
  for_each = toset(local.pttp_tgw_destination_cidr_blocks)
  source   = "./modules/tgw-route"

  destination_cidr_block = each.key

  transit_gateway_id = local.pttp_tgw_id
  route_tables       = local.route_tables
}

module "tgw_route_live_2" {
  for_each = toset(local.pttp_tgw_live_2_destination_cidr_blocks)
  source   = "./modules/tgw-route"

  destination_cidr_block = each.key

  transit_gateway_id = local.pttp_tgw_id
  route_tables       = local.route_tables_live_2
}
