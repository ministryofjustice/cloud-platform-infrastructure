output "cluster_name" {
  value = local.cluster_name
}

output "cluster_domain_name" {
  value = trimsuffix(local.cluster_base_domain_name, ".")
}

output "hosted_zone_id" {
  value = aws_route53_zone.cluster.zone_id
}

output "oidc_issuer_url" {
  value = "https://${var.auth0_tenant_domain}/"
}

output "oidc_kubernetes_client_id" {
  value = module.auth0.oidc_kubernetes_client_id
}

output "oidc_kubernetes_client_secret" {
  value = module.auth0.oidc_kubernetes_client_secret
}

output "oidc_components_client_id" {
  value = module.auth0.oidc_components_client_id
}

output "oidc_components_client_secret" {
  value = module.auth0.oidc_components_client_secret
}


