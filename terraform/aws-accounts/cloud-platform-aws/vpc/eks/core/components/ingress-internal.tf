module "ingress_controllers_internal" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=3.1.2"

  count = terraform.workspace == "live" ? 1 : 0

  replica_count            = terraform.workspace == "live" ? "3" : "1"
  controller_name          = "internal"
  proxy_response_buffering = "on"
  enable_anti_affinity     = terraform.workspace == "live" ? true : false
  enable_latest_tls        = true
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")
  default_cert             = "ingress-controllers/internal-certificate"
  enable_chainguard        = true

  # Enable this when we remove the module "ingress_controllers"
  enable_external_dns_annotation = true

  internal_load_balancer = true

  memory_requests = lookup(local.live_workspace, terraform.workspace, false) ? "2Gi" : "512Mi"
  memory_limits   = lookup(local.live_workspace, terraform.workspace, false) ? "4Gi" : "1Gi"

  default_tags = local.default_tags

  depends_on = [
    module.label_pods_controller
  ]
}
