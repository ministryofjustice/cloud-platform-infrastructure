output "eks_worker_iam_role_arn" {
  value = module.eks.worker_iam_role_arn
}

output "eks_worker_iam_role_name" {
  value = module.eks.worker_iam_role_name
}

output "cluster_name" {
  value = local.cluster_name
}

output "vpc_id" {
  value = data.aws_vpc.selected.id
}

output "internal_subnets" {
  value = data.aws_subnet.private_cidrs.*.cidr_block
}

output "internal_subnets_ids" {
  value = tolist(data.aws_subnet_ids.private.ids)
}

output "base_route53_hostzone" {
  value = local.base_route53_hostzone
}

output "cluster_domain_name" {
  value = local.cluster_base_domain_name
}

output "oidc_issuer_url" {
  value = "https://${local.auth0_tenant_domain}/"
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
