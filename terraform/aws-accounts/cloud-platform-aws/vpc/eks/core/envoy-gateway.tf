module "envoy_gateway" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-envoy-gateway?ref=1.0.1"

  envoy_controller_replicas = lookup(local.live_workspace, terraform.workspace, false) ? 3 : 2
  cpu_requests              = lookup(local.live_workspace, terraform.workspace, false) ? "250m" : "100m"
  memory_requests           = lookup(local.live_workspace, terraform.workspace, false) ? "1Gi" : "512Mi"
  memory_limits             = lookup(local.live_workspace, terraform.workspace, false) ? "2Gi" : "1Gi"

  depends_on = [module.gatekeeper]
}