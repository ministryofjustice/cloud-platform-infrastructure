module "non_prod_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.14.7"
  count  = terraform.workspace == "live" ? 1 : 0

  replica_count            = "6"
  controller_name          = "default-non-prod"
  enable_cross_zone_lb     = false
  enable_anti_affinity     = terraform.workspace == "live" ? true : false
  upstream_keepalive_time  = "120s"
  enable_latest_tls        = true
  proxy_response_buffering = "on"
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")

  enable_external_dns_annotation = false // this creates the wildcards in external dns

  memory_requests = "5Gi"
  memory_limits   = "20Gi"

  default_tags = local.default_tags

  depends_on = [
    module.label_pods_controller
  ]
}
