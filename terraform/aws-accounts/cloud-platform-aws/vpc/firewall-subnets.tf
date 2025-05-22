resource "aws_subnet" "firewall_subnets" {
  count = 3

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = cidrsubnet("172.20.255.0/24", 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge({
    Name         = "${local.vpc_name}-firewall-${var.availability_zones[count.index]}"
    SubnetType   = "Firewall"
    Terraform    = "true"
    Cluster      = local.vpc_name
    Domain       = local.vpc_base_domain_name
  }, local.cluster_tags)
}

