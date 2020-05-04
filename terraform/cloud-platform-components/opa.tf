
module "opa" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=0.0.2"
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  # boolean expression for applying opa valid hostname for test clusters only.
  enable_invalid_hostname_policy = terraform.workspace == local.live_workspace ? false : true
  dependence_deploy = null_resource.deploy
}
