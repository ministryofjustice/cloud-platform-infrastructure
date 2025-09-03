module "external_secrets_operator" {
  source                      = "github.com/ministryofjustice/cloud-platform-terraform-external-secrets-operator?ref=0.2.0"
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  secrets_prefix              = terraform.workspace
}
