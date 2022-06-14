output "cluster_name" {
  value = local.cluster_name
}

output "cluster_domain_name" {
  value = local.cluster_base_domain_name
}

output "hosted_zone_id" {
  value = module.cluster_dns.cluster_dns_zone_id
}

