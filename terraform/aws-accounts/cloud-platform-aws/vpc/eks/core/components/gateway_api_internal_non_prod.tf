module "gateway_api_internal_non_prod" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-gateway-api?ref=1.1.1"
  count  = terraform.workspace == "live" ? 1 : 0

  gateway_name           = "internal-non-prod"
  cluster_base_domain    = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  lb_name_prefix         = terraform.workspace
  internal_load_balancer = true
  default_cert           = "internal-non-prod-certificate"
  enable_coraza          = true

  enable_anti_affinity = true
  envoy_proxy_replicas = 3
  memory_requests      = lookup(local.live_workspace, terraform.workspace, false) ? "1Gi" : "512Mi"
  memory_limits        = lookup(local.live_workspace, terraform.workspace, false) ? "2Gi" : "1Gi"

  default_tags = local.default_tags

  depends_on = [module.gateway_api_default]
}