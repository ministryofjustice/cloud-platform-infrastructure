
module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.0.4"

  enable_starter_pack = terraform.workspace == local.live_workspace ? false : true
  dependence_deploy   = null_resource.deploy
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}
