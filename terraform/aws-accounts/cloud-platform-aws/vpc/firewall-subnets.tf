resource "aws_subnet" "firewall_private" {
  count = 3

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, count.index + 4)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = { Name = "${local.vpc_name}-firewall-${var.availability_zones[count.index]}" }
}

resource "aws_route_table" "firewall_private" {
  count = 3

  vpc_id = module.vpc.vpc_id
  tags   = { Name = "${local.vpc_name}-firewall-${var.availability_zones[count.index]}" }
}

resource "aws_route_table_association" "firewall_private" {
  count = 3

  subnet_id      = aws_subnet.firewall_private[count.index].id
  route_table_id = aws_route_table.firewall_private[count.index].id
}
