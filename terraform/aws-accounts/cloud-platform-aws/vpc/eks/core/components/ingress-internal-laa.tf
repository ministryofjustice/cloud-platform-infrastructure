module "ingress_controllers_laa" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=3.1.0"

  count = terraform.workspace == "live" ? 1 : 0

  replica_count            = terraform.workspace == "live" ? "3" : "1"
  controller_name          = "internal-laa"
  proxy_response_buffering = "on"
  enable_anti_affinity     = terraform.workspace == "live" ? true : false
  enable_latest_tls        = true
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")
  enable_chainguard        = true

  # Enable this when we remove the module "ingress_controllers"
  enable_external_dns_annotation = false

  internal_load_balancer = true

  memory_requests = lookup(local.live_workspace, terraform.workspace, false) ? "2Gi" : "512Mi"
  memory_limits   = lookup(local.live_workspace, terraform.workspace, false) ? "4Gi" : "1Gi"

  default_tags = local.default_tags

  depends_on = [
    module.label_pods_controller
  ]
}

module "internal_laa_ingress_controllers_validator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-validation-controller?ref=0.1.0"
  count  = terraform.workspace == "live" ? 1 : 0

  replica_count      = "3"
  controller_name    = "internal-laa"
  memory_requests    = "2Gi"
  memory_limits      = "4Gi"
  cluster            = terraform.workspace
  validator_registry = "754256621582.dkr.ecr.eu-west-2.amazonaws.com"
  validator_image    = "webops/cloud-platform-terraform-ingress-validation-controller"
  validator_tag      = "ff3f53388052256d48606739aaa65092c234f1c8"
  validator_digest   = "sha256:86586f2105b2d5c57e0c0c45e2216f6ad666992402122455138402c6e1d6caeb"

  default_tags = local.default_tags

  depends_on = [module.ingress_controllers_v1]
}
