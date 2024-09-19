resource "aws_subnet" "eks_private" {
  count = 3

  vpc_id            = module.vpc.vpc_id
  cidr_block        = cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, count.index + 4)
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge({
    Name                             = "${local.vpc_name}-private-${var.availability_zones[count.index]}"
    SubnetType                       = "EKS-Private"
    "kubernetes.io/role/internal-elb" = "1"
    Terraform = "true"
    Cluster   = local.vpc_name
    Domain    = local.vpc_base_domain_name
  }, local.cluster_tags)
}

resource "aws_route_table_association" "eks_private" {
  count = 3

  subnet_id      = aws_subnet.eks_private[count.index].id
  route_table_id = module.vpc.private_route_table_ids[count.index]
}
