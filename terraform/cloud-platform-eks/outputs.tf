output "cluster_name" {
  value = local.cluster_name
}

output "cluster_domain_name" {
  value = local.cluster_base_domain_name
}

output "network_id" {
  value = module.cluster_vpc.vpc_id
}

output "network_cidr_block" {
  value = module.cluster_vpc.vpc_cidr_block
}

output "availability_zones" {
  value = var.availability_zones
}

output "vpc_id" {
  value = module.cluster_vpc.vpc_id
}

output "internal_subnets" {
  value = var.internal_subnets
}

output "internal_subnets_ids" {
  value = module.cluster_vpc.private_subnets
}

output "external_subnets" {
  value = var.external_subnets
}

output "external_subnets_ids" {
  value = module.cluster_vpc.public_subnets
}

output "instance_key_name" {
  value = aws_key_pair.cluster.key_name
}

output "oidc_issuer_url" {
  value = local.oidc_issuer_url
}

output "oidc_kubernetes_client_id" {
  value = auth0_client.kubernetes.client_id
}

output "oidc_kubernetes_client_secret" {
  value = auth0_client.kubernetes.client_secret
}

output "oidc_components_client_id" {
  value = auth0_client.components.client_id
}

output "oidc_components_client_secret" {
  value = auth0_client.components.client_secret
}

output "eks_worker_iam_role_arn" {
  value = module.eks.worker_iam_role_arn
}

output "eks_worker_iam_role_name" {
  value = module.eks.worker_iam_role_name
}


