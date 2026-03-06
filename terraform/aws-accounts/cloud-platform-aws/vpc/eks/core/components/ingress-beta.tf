module "beta_ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.20.0"
  count  = terraform.workspace == "live" ? 1 : 0

  replica_count            = "3"
  controller_name          = "beta"
  proxy_response_buffering = "on"
  enable_anti_affinity     = terraform.workspace == "live" ? true : false
  enable_latest_tls        = true
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")

  default_cert             = "ingress-controllers/beta-certificate"

  # Enable this when we remove the module "ingress_controllers"
  enable_external_dns_annotation = true

  memory_requests = "1Gi"
  memory_limits   = "2Gi"

  default_tags = local.default_tags

  depends_on = [
    module.label_pods_controller
  ]
}



#######################################
# beta class validation controller #
#######################################
module "default_ingress_controllers_validator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-validation-controller?ref=0.1.0"
  count  = terraform.workspace == "live" ? 1 : 0

  replica_count        = "3"
  controller_name      = "beta"
  enable_anti_affinity = terraform.workspace == "live" ? true : false
  memory_requests      = lookup(local.live_workspace, terraform.workspace, false) ? "4Gi" : "512Mi"
  memory_limits        = lookup(local.live_workspace, terraform.workspace, false) ? "20Gi" : "2Gi"
  cluster              = terraform.workspace
  validator_registry   = "754256621582.dkr.ecr.eu-west-2.amazonaws.com"
  validator_image      = "webops/cloud-platform-terraform-ingress-validation-controller"
  validator_tag        = "ff3f53388052256d48606739aaa65092c234f1c8"
  validator_digest     = "sha256:86586f2105b2d5c57e0c0c45e2216f6ad666992402122455138402c6e1d6caeb"

  default_tags = local.default_tags

  depends_on = [module.ingress_controllers_v1]

}
