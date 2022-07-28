output "eks_worker_iam_role_arn" {
  value = module.eks.worker_iam_role_arn
}

output "eks_worker_iam_role_name" {
  value = module.eks.worker_iam_role_name
}

output "vpc_id" {
  value = data.aws_vpc.selected.id
}

output "internal_subnets_ids" {
  value = sort(tolist(data.aws_subnets.private.ids))
}

output "external_subnets_ids" {
  value = sort(tolist(data.aws_subnets.public.ids))
}

output "cluster_domain_name" {
  value = local.cluster_base_domain_name
}

output "oidc_issuer_url" {
  value = "https://justice-cloud-platform.eu.auth0.com/"
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

# EKS
output "cluster_oidc_issuer_url" {
  value = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
}

output "cluster_id" {
  value = module.eks.cluster_id
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
