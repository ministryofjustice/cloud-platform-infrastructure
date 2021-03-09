output "cluster_name" {
  value = local.cluster_name
}

output "cluster_domain_name" {
  value = local.cluster_base_domain_name
}

output "kops_state_store" {
  value = data.aws_s3_bucket.kops_state.bucket
}

output "availability_zones" {
  value = var.availability_zones
}

output "internal_subnets" {
  value = var.internal_subnets
}

output "external_subnets" {
  value = var.external_subnets
}

output "hosted_zone_id" {
  value = module.cluster_dns.cluster_dns_zone_id
}

output "oidc_issuer_url" {
  value = local.oidc_issuer_url
}

output "oidc_kubernetes_client_id" {
  value = module.auth0.oidc_kubernetes_client_id
}

output "oidc_kubernetes_client_secret" {
  value     = module.auth0.oidc_kubernetes_client_secret
  sensitive = true
}

output "oidc_components_client_id" {
  value = module.auth0.oidc_components_client_id
}

output "oidc_components_client_secret" {
  value     = module.auth0.oidc_components_client_secret
  sensitive = true
}

# This outputs are used by cloud-platform-environment repo
output "vpc_id" {
  value = module.kops.vpc_id
}

output "internal_subnets_ids" {
  value = module.kops.internal_subnets_ids
}

output "external_subnets_ids" {
  value = module.kops.external_subnets_ids
}

output "network_id" {
  value = module.kops.network_id
}

output "network_cidr_block" {
  value = module.kops.network_cidr_block
}
