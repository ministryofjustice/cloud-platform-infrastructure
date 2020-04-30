
module "ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=master"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = terraform.workspace == local.live_workspace ? true : false

  # This module requires helm and OPA already deployed
  dependence_prometheus  = module.prometheus.helm_prometheus_operator_status
  dependence_deploy      = null_resource.deploy
  dependence_opa         = module.opa.helm_opa_status
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
}
