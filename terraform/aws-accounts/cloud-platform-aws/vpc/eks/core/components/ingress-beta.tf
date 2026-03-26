############################################################
# beta class ingress controller - modsec and owasp enabled #
############################################################

# module "beta_ingress_controllers" {
#   source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=3.1.0"
#   count  = terraform.workspace == "live" ? 1 : 0

#   replica_count            = "3"
#   is_non_prod_modsec       = true
#   controller_name          = "beta"
#   proxy_response_buffering = "on"
#   enable_anti_affinity     = terraform.workspace == "live" ? true : false
#   enable_latest_tls        = true
#   cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
#   is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
#   enable_modsec            = true
#   enable_owasp             = true

#   default_cert = "ingress-controllers/beta-certificate"

#   # Enable this when we remove the module "ingress_controllers"
#   enable_external_dns_annotation = true

#   opensearch_app_logs_host     = lookup(var.opensearch_app_host_map, terraform.workspace, "placeholder-opensearch")
#   opensearch_modsec_audit_host = lookup(var.elasticsearch_modsec_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
#   cluster                      = terraform.workspace
#   fluent_bit_version           = "4.0.2-amd64"

#   memory_requests = "2Gi"
#   memory_limits   = "4Gi"

#   default_tags = local.default_tags

#   enable_chainguard = true

#   depends_on = [
#     module.label_pods_controller
#   ]
# }

#######################################
# beta class validation controller    #
#######################################

# module "beta_ingress_controllers_validator" {
#   source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-validation-controller?ref=0.1.0"
#   count  = terraform.workspace == "live" ? 1 : 0

#   replica_count      = "3"
#   controller_name    = "beta"
#   memory_requests    = "2Gi"
#   memory_limits      = "4Gi"
#   cluster            = terraform.workspace
#   enable_modsec      = true
#   enable_owasp       = true
#   validator_registry = "754256621582.dkr.ecr.eu-west-2.amazonaws.com"
#   validator_image    = "webops/cloud-platform-terraform-ingress-validation-controller"
#   validator_tag      = "ff3f53388052256d48606739aaa65092c234f1c8"
#   validator_digest   = "sha256:86586f2105b2d5c57e0c0c45e2216f6ad666992402122455138402c6e1d6caeb"

#   default_tags = local.default_tags

#   depends_on = [module.ingress_controllers_v1]
# }
