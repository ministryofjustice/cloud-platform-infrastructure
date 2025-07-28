module "modsec_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.15.3"

  replica_count            = terraform.workspace == "live" ? "12" : "3"
  controller_name          = "modsec"
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")
  proxy_response_buffering = "on"
  enable_anti_affinity     = terraform.workspace == "live" ? true : false
  enable_modsec            = true
  enable_owasp             = true
  enable_latest_tls        = true
  memory_requests          = lookup(local.live_workspace, terraform.workspace, false) ? "4Gi" : "512Mi"
  memory_limits            = lookup(local.live_workspace, terraform.workspace, false) ? "20Gi" : "2Gi"

  opensearch_app_logs_host     = lookup(var.opensearch_app_host_map, terraform.workspace, "placeholder-opensearch")
  opensearch_modsec_audit_host = lookup(var.elasticsearch_modsec_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  cluster                      = terraform.workspace
  fluent_bit_version           = "4.0.2-amd64"

  default_tags = local.default_tags

  # Required variables for tags in S3-Bucket submodule
  business_unit = local.default_tags["business-unit"]
  application   = local.default_tags["application"]
  is_production = local.default_tags["is-production"]
  team_name     = local.default_tags["owner"]

  depends_on = [module.ingress_controllers_v1]
}
