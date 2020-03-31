
module "opa" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=0.0.1"

  dependence_deploy = null_resource.deploy
}
