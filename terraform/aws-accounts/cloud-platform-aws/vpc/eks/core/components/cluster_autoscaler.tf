module "cluster_autoscaler" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-cluster-autoscaler?ref=1.13.0"

  enable_overprovision        = lookup(local.prod_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_id              = data.terraform_remote_state.cluster.outputs.cluster_id
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  # These values are for tuning live cluster overprovisioner memory and CPU requests
  live_memory_request = "1800Mi"
  live_cpu_request    = "200m"

  depends_on = [
    module.label_pods_controller,
    module.monitoring
  ]
}
