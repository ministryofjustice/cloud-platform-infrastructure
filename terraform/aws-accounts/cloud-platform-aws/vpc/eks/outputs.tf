# output "eks_worker_iam_role_arn" {
#   value       = module.eks.worker_iam_role_arn
#   description = "Default IAM role ARN for EKS worker groups"
# }

# output "eks_worker_iam_role_name" {
#   value       = module.eks.worker_iam_role_name
#   description = "Default IAM role name for EKS worker groups"
# }

output "vpc_id" {
  value       = data.aws_vpc.selected.id
  description = "VPC ID for current cluster/terraform workspace"
}

output "internal_subnets" {
  value       = data.aws_subnet.private_cidrs[*].cidr_block
  description = "Private subnet CIDR ranges"
}

output "internal_subnets_ids" {
  value       = sort(tolist(data.aws_subnets.private.ids))
  description = "Private subnet IDs"
}

output "external_subnets_ids" {
  value       = sort(tolist(data.aws_subnets.public.ids))
  description = "Public subnet IDs"
}

output "cluster_domain_name" {
  value       = local.fqdn
  description = "FQDN for the cluster"
}

output "oidc_issuer_url" {
  value       = "https://justice-cloud-platform.eu.auth0.com/"
  description = "OIDC URL for authentication"
}

output "oidc_kubernetes_client_id" {
  value       = module.auth0.oidc_kubernetes_client_id
  description = "Kubernetes OIDC Client ID"
}

output "oidc_kubernetes_client_secret" {
  value       = module.auth0.oidc_kubernetes_client_secret
  sensitive   = true
  description = "Kubernetes OIDC Client Secret"
}

output "oidc_components_client_id" {
  value       = module.auth0.oidc_components_client_id
  description = "Kubernetes OIDC Client ID"
}

output "oidc_components_client_secret" {
  value       = module.auth0.oidc_components_client_secret
  sensitive   = true
  description = "Components OIDC Client Secret"
}

# EKS
output "cluster_oidc_issuer_url" {
  value       = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  description = "URL on the EKS cluster OIDC Issuer"
}

output "cluster_id" {
  value       = module.eks.cluster_id
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready."
}
output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The endpoint for your EKS Kubernetes API."
}
