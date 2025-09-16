data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

/* Because the route table details aren't fully exposed this allows us to map route tables to subnets and from there
we can get the correct availability zone */
data "aws_route_table" "intra" {
  for_each = { for i in range(local.num_azs) : i => i }
  filter {
    name   = "tag:Name"
    values = ["${module.vpc.name}-${local.intra_subnet_suffix}-${local.azs[each.key]}"]
  }
  vpc_id = module.vpc.vpc_id
}

data "aws_ec2_transit_gateway" "cloud-platform-transit-gateway" {
  filter {
    name   = "tag:Name"
    values = ["cloud-platform-transit-gateway"]
  }
}

locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, local.num_azs)
  num_azs  = 3

  subnet_cidrs    = cidrsubnets("10.0.0.0/16", 12, 12, 12, 12, 12, 12)
  private_subnets = slice(local.subnet_cidrs, 0, 3)
  intra_subnets   = slice(local.subnet_cidrs, 3, 6)

  intra_subnet_suffix   = "transit"
  private_subnet_suffix = "firewall"

  private_route_table_ids = toset(module.vpc.private_route_table_ids)

  /* Create a map of Availability Zones with corresponding VPC Endpoint IDs */
  az_to_endpoint_id = {
    for sync in module.inspection-firewall.status[0].sync_states :
    sync.availability_zone => sync.attachment[0].endpoint_id
  }

  az_to_route_table_id = {
    for idx, az in local.azs :
    az => data.aws_route_table.intra[tostring(idx)].id
  }

  az_to_route_table_and_endpoint = {
    for az in local.azs : az => {
      route_table_id  = local.az_to_route_table_id[az]
      vpc_endpoint_id = local.az_to_endpoint_id[az]
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "inspection-vpc"

  azs  = local.azs
  cidr = local.vpc_cidr

  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  create_igw                           = false
  create_multiple_intra_route_tables   = true

  enable_flow_log = true

  intra_subnets       = local.intra_subnets
  intra_subnet_names  = [for key in local.azs : "inspection-vpc-transit-${key}"]
  intra_subnet_suffix = local.intra_subnet_suffix

  private_subnets       = local.private_subnets
  private_subnet_names  = [for key in local.azs : "inspection-vpc-firewall-${key}"]
  private_subnet_suffix = local.private_subnet_suffix
}

resource "aws_route" "transit-to-firewall" {
  for_each               = local.az_to_route_table_and_endpoint
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = each.value["route_table_id"]
  vpc_endpoint_id        = each.value["vpc_endpoint_id"]
}

resource "aws_route" "firewall-to-transit" {
  for_each               = local.private_route_table_ids
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = each.key
  transit_gateway_id     = data.aws_ec2_transit_gateway.cloud-platform-transit-gateway.id
}
