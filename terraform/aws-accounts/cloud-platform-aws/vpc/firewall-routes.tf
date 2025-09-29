locals {
  firewall_endpoints = {
    for state in module.cloud-platform-firewall.status[0].sync_states :
    state.availability_zone => state.attachment[0].endpoint_id
  }
}

// Route internet bound traffic from firewall to NAT Gateways (one per AZ since one_nat_gateway_per_az = true)
// This ensures egress traffic from the firewall to the NAT gateways
resource "aws_route" "firewall_to_nat" {
  count = 3

  route_table_id         = aws_route_table.firewall_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.vpc.natgw_ids[count.index]
}

// Route internet bound traffic from private subnets to to corresponding AZ firewall endpoints
// This ensures egress traffic initiated from the private subnets to the firewall
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

// Routes private subnet bound traffic from the public subnet to corresponding AZ firewall endpoints
// This ensures returning egress traffic to route through the firewall
// This ensures ingress traffic from NLB to be routed through the firewall
resource "aws_route" "public_subnets_to_private" {
  count = length(module.vpc.public_route_table_ids)

  route_table_id         = module.vpc.public_route_table_ids[count.index]
  destination_cidr_block = module.vpc.private_subnets_cidr_blocks[count.index]
  vpc_endpoint_id        = local.firewall_endpoints[var.availability_zones[count.index]]

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

  depends_on = [
    module.cloud-platform-firewall,
    module.vpc,
    aws_subnet.eks_private
  ]
}

// Route public subnet bound traffic from private subnets to corresponding AZ firewall endpoints
// This ensures returning ingress traffic to route through the firewall
resource "aws_route" "private_subnets_to_public" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = module.vpc.public_subnets_cidr_blocks[count.index]
  vpc_endpoint_id        = local.firewall_endpoints[var.availability_zones[count.index]]

  depends_on = [
    module.cloud-platform-firewall,
    module.vpc
  ]
}
