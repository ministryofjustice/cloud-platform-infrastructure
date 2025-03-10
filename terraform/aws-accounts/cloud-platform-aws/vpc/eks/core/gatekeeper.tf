module "gatekeeper" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-gatekeeper?ref=1.14.1"

  dryrun_map = {
    service_type                       = false,
    snippet_allowlist                  = false,
    modsec_snippet_nginx_class         = false,
    modsec_nginx_class                 = false,
    ingress_clash                      = false,
    hostname_length                    = false,
    external_dns_identifier            = terraform.workspace == "live" ? false : true,
    external_dns_weight                = terraform.workspace == "live" ? false : true,
    valid_hostname                     = lookup(local.prod_2_workspace, terraform.workspace, false),
    warn_service_account_secret_delete = false,
    user_ns_requires_psa_label         = false,
    deprecated_apis_1_26               = false,
    deprecated_apis_1_27               = false,
    deprecated_apis_1_29               = true,
    warn_kubectl_create_sa             = false,
    # There are violations on system namespaces and until that is cleared, this
    # constraint will be in dryrun mode
    lock_priv_capabilities        = true,
    allow_duplicate_hostname_yaml = false,
    block_ingresses               = true,
  }

  cluster_domain_name                  = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  cluster_color                        = terraform.workspace == "live" ? "green" : "black"
  integration_test_zone                = data.aws_route53_zone.integrationtest.name
  constraint_violations_max_to_display = 25

  is_production        = lookup(local.prod_2_workspace, terraform.workspace, false) ? "true" : "false"
  environment_name     = lookup(local.prod_2_workspace, terraform.workspace, false) ? "production" : "development"
  out_of_hours_alert   = lookup(local.prod_2_workspace, terraform.workspace, false) ? "true" : "false"
  controller_mem_limit = terraform.workspace == "live" ? "4Gi" : "1Gi"
  controller_mem_req   = terraform.workspace == "live" ? "1Gi" : "512Mi"
  audit_mem_limit      = terraform.workspace == "live" ? "16Gi" : "1Gi"
  audit_mem_req        = terraform.workspace == "live" ? "4Gi" : "512Mi"
}

