module "ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.18.2"

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

  memory_requests = lookup(local.live_workspace, terraform.workspace, false) ? "10Gi" : "512Mi"
  memory_limits   = lookup(local.live_workspace, terraform.workspace, false) ? "10Gi" : "2Gi"

  default_tags = local.default_tags

  depends_on = [
    module.label_pods_controller
  ]
}


module "non_prod_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=3.1.0"
  count  = terraform.workspace == "live" ? 1 : 0

  replica_count            = "15"
  controller_name          = "default-non-prod"
  enable_cross_zone_lb     = false
  enable_anti_affinity     = terraform.workspace == "live" ? true : false
  upstream_keepalive_time  = "120s"
  enable_latest_tls        = true
  proxy_response_buffering = "on"
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")
  enable_chainguard        = true

  enable_external_dns_annotation = false // this creates the wildcards in external dns

  memory_requests = "10Gi"
  memory_limits   = "10Gi"

  default_tags = local.default_tags

  depends_on = [
    module.label_pods_controller
  ]
}

module "modsec_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.18.2"

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

module "non_prod_modsec_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=3.1.0"

  count = terraform.workspace == "live" ? 1 : 0

  replica_count            = "10"
  is_non_prod_modsec       = true
  controller_name          = "modsec-non-prod"
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
  enable_chainguard        = true

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

module "ingress_controllers_laa" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.18.2"

  count = terraform.workspace == "live" ? 1 : 0

  replica_count            = terraform.workspace == "live" ? "3" : "1"
  controller_name          = "internal-laa"
  proxy_response_buffering = "on"
  enable_anti_affinity     = terraform.workspace == "live" ? true : false
  enable_latest_tls        = true
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")

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

module "ingress_controllers_internal" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.18.2"

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

module "ingress_controllers_internal_non_prod" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=3.0.0"

  count = terraform.workspace == "live" ? 1 : 0

  replica_count            = terraform.workspace == "live" ? "2" : "1"
  controller_name          = "internal-non-prod"
  proxy_response_buffering = "on"
  enable_anti_affinity     = false
  enable_latest_tls        = true
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")
  default_cert             = "ingress-controllers/internal-non-prod-certificate"
  enable_chainguard        = false

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

###########################
# validation controllers  #
###########################

# non-prod-modsec
module "modsec_non_prod_ingress_controllers_validator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-validation-controller?ref=0.1.0"
  count  = terraform.workspace == "live" ? 1 : 0

  replica_count      = "3"
  controller_name    = "modsec-non-prod"
  memory_requests    = "2Gi"
  memory_limits      = "4Gi"
  cluster            = terraform.workspace
  enable_modsec      = true
  enable_owasp       = true
  validator_registry = "754256621582.dkr.ecr.eu-west-2.amazonaws.com"
  validator_image    = "webops/cloud-platform-terraform-ingress-validation-controller"
  validator_tag      = "ff3f53388052256d48606739aaa65092c234f1c8"
  validator_digest   = "sha256:86586f2105b2d5c57e0c0c45e2216f6ad666992402122455138402c6e1d6caeb"

  default_tags = local.default_tags

  depends_on = [module.ingress_controllers_v1]

}

# default-non-prod
module "default_non_prod_ingress_controllers_validator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-validation-controller?ref=0.1.0"
  count  = terraform.workspace == "live" ? 1 : 0

  replica_count      = "3"
  controller_name    = "default-non-prod"
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
