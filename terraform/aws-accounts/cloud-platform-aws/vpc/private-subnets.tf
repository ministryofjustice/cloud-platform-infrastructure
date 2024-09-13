resource "aws_subnet" "private" {
  count = 3

  vpc_id            = module.vpc.vpc_id
  cidr_block        = cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, count.index + 1)
  availability_zone = var.availability_zones[count.index]

  tags = merge({
    Name       = "${local.vpc_name}-${var.availability_zones[count.index]}"
    SubnetType = "Private"
    "kubernetes.io/role/internal-elb" = "1"
    Terraform = "true"
    Cluster   = local.vpc_name
    Domain    = local.vpc_base_domain_name
  }, local.cluster_tags)
}

resource "aws_eip" "nat" {
  count = 3
  domain = "vpc"

  tags = {
    Name = "${local.vpc_name}-${var.availability_zones[count.index]}"
    Terraform = "true"
    Cluster   = local.vpc_name
    Domain    = local.vpc_base_domain_name
  }
}

resource "aws_nat_gateway" "this" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = module.vpc.public_subnets[count.index] # NAT gateways are created in public subnets

  tags = {
    Name = "${local.vpc_name}-${var.availability_zones[count.index]}"
    Terraform = "true"
    Cluster   = local.vpc_name
    Domain    = local.vpc_base_domain_name
  }
}

resource "aws_route_table" "private" {
  count  = 3
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${local.vpc_name}-${var.availability_zones[count.index]}"
    Terraform = "true"
    Cluster   = local.vpc_name
    Domain    = local.vpc_base_domain_name
  }
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route" "private_nat_gateway" {
  count          = 3
  route_table_id = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.this[count.index].id
}