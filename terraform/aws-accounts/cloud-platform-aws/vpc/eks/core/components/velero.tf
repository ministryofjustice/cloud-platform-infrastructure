module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=2.6.0"

  enable_velero               = lookup(local.prod_2_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  node_agent_cpu_requests     = "2m"

  depends_on = [
    module.label_pods_controller
  ]
}
