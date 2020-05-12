
module "starter_pack" {
  source    = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=improvements-and-helm3"

  #enable_starter_pack = terraform.workspace == local.live_workspace ? false : true
  enable_starter_pack = false
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}
