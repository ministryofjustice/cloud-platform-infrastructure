output "vpc_name" {
  value = local.vpc_name
}

output "vpc_domain_name" {
  value = local.vpc_base_domain_name
}

output "network_id" {
  value = module.vpc.vpc_id
}

output "network_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

output "availability_zones" {
  value = var.availability_zones
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "internal_subnets" {
  value = var.internal_subnets
}

output "internal_subnets_ids" {
  value = module.vpc.private_subnets
}

output "external_subnets" {
  value = var.external_subnets
}

output "external_subnets_ids" {
  value = module.vpc.public_subnets
}

output "nat_gateway_ips" {
  value = module.vpc.nat_public_ips
}

output "private_route_tables" {
  value = module.vpc.private_route_table_ids
}

output "public_route_tables" {
  value = module.vpc.public_route_table_ids
}