module "ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.14.7"

  replica_count            = terraform.workspace == "live" ? "30" : "3"
  controller_name          = "default"
  proxy_response_buffering = "on"
  enable_anti_affinity     = terraform.workspace == "live" ? true : false
  enable_latest_tls        = true
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")

  # Enable this when we remove the module "ingress_controllers"
  enable_external_dns_annotation = true

  memory_requests = lookup(local.live_workspace, terraform.workspace, false) ? "5Gi" : "512Mi"
  memory_limits   = lookup(local.live_workspace, terraform.workspace, false) ? "20Gi" : "2Gi"

  default_tags = local.default_tags

  depends_on = [
    module.label_pods_controller
  ]
}
