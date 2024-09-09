module "cni_metrics_helper" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-cni-metrics-helper?ref=0.3.0"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  depends_on = [kubectl_manifest.prometheus_operator_crds]
}