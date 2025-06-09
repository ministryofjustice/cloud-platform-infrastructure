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
  for_each = {
    for i in range(local.num_azs) : i => i
  }

  vpc_id = module.vpc.vpc_id

  filter {
    name   = "tag:Name"
    values = ["intra-${local.azs[each.key]}"]
  }
}

locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, local.num_azs)
  num_azs  = 3

  subnet_cidrs    = cidrsubnets("10.0.0.0/16", 12, 12, 12, 12, 12, 12)
  private_subnets = slice(local.subnet_cidrs, 0, 3)
  intra_subnets   = slice(local.subnet_cidrs, 3, 6)

  /* Create a map of Availability Zones with corresponding VPC Endpoint IDs */
  az_to_endpoint_id = {
    for sync in module.cloud-platform-firewall.status[0].sync_states :
    sync.availability_zone => sync.attachment[0].endpoint_id
  }

  az_to_route_table_id = {
    for az, subnet_id in local.az_to_subnet_id :
    az => data.aws_route_table.intra[subnet_id].id
  }

  az_to_subnet_id = {
    for subnet in module.vpc.intra_subnet_objects :
    subnet.availability_zone => subnet.id
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

  intra_subnets      = local.intra_subnets
  intra_subnet_names = [for key in local.azs : "transit-${key}"]

  private_subnets      = local.private_subnets
  private_subnet_names = [for key in local.azs : "firewall-${key}"]
}

resource "aws_route" "transit-to-firewall" {
  for_each               = local.az_to_route_table_and_endpoint
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = each.value["route_table_id"]
  vpc_endpoint_id        = each.value["vpc_endpoint_id"]
}

/* Add a route back to the transit gateway once that's been constructed and attached
resource "aws_route" "firewall-to-transit" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = module.vpc.private_route_table_ids
  transit_gateway_id     = ""
}
*/
