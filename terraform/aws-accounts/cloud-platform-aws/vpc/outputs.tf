output "vpc_name" {
  value       = local.vpc_name
  description = "VPC name (also terraform workspace)"
}

output "vpc_domain_name" {
  value       = local.vpc_base_domain_name
  description = "VPC base domain name"
}

output "network_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "network_cidr_block" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC CIDR range"
}

output "availability_zones" {
  value       = var.availability_zones
  description = "Used availability zones"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "internal_subnets" {
  value       = concat(module.vpc.private_subnets_cidr_blocks, tolist(aws_subnet.eks_private[*].cidr_block), tolist(aws_subnet.firewall_private[*].cidr_block))
  description = "List of subnet CIDR blocks that are not publicly accessible"
}

output "internal_subnets_ids" {
  value       = concat(module.vpc.private_subnets, tolist(aws_subnet.eks_private[*].id), tolist(aws_subnet.firewall_private[*].id))
  description = "Private subnet IDs"
}

output "external_subnets" {
  description = "List of subnet CIDR blocks that are publicly accessible"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "external_subnets_ids" {
  value       = module.vpc.public_subnets
  description = "Public subnet IDs"
}

output "firewall_subnets_ids" {
  description = "Firewall subnet IDs"
  value       = aws_subnet.firewall_private[*].id
}

output "nat_gateway_ips" {
  value       = module.vpc.nat_public_ips
  description = "List of public Elastic IPs created for AWS NAT Gateway"
}

output "private_route_tables" {
  value       = module.vpc.private_route_table_ids
  description = "List of IDs of private route tables"
}

output "public_route_tables" {
  value       = module.vpc.public_route_table_ids
  description = "List of IDs of public route tables"
}

output "vpc_flowlogs_bucket_arn" {
  value       = module.flowlogs.s3_bucket_arn
  description = "VPC Flowlogs bucket arn"
}

output "vpc_flowlogs_bucket_id" {
  value       = module.flowlogs.s3_bucket_id
  description = "VPC Flowlogs bucket id"
}

output "route53_query_log_bucket_arn" {
  value       = module.route53_query_log.s3_bucket_arn
  description = "Route53 query log bucket arn"
}

output "route53_query_log_bucket_id" {
  value       = module.route53_query_log.s3_bucket_id
  description = "Route53 query log bucket id"
}