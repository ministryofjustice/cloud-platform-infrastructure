
module "cert_manager" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=1.5.1"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])

  # Requiring Prometheus taints the default cert null_resource on any monitoring upgrade, 
  # but cluster creation fails without, so will have to be temporarily disabled when upgrading
  dependence_prometheus = module.monitoring.prometheus_operator_crds_status
  dependence_opa        = "ignore"

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.9.2"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])

  dependence_prometheus       = module.monitoring.prometheus_operator_crds_status
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=0.3.5"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name = lookup(local.live1_cert_dns_name, terraform.workspace, "")

  # This module requires prometheus and cert-manager
  dependence_prometheus  = "ignore"
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
  dependence_opa         = "ignore"
  # It depends on complete cert-manager module
  depends_on = [module.cert_manager]
}

module "modsec_ingress_controllers" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-modsec-ingress-controller?ref=0.3.2"

  controller_name = "modsec01"
  replica_count   = "6"

  depends_on = [module.ingress_controllers]
}

module "ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.0.11"

  replica_count       = "6"
  controller_name     = "default"
  enable_latest_tls   = true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name = lookup(local.live1_cert_dns_name, terraform.workspace, "")

  # Enable this when we remove the module "ingress_controllers"
  enable_external_dns_annotation = false
  depends_on = [
    module.cert_manager,
    module.monitoring.prometheus_operator_crds_status
  ]

}

module "modsec_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.0.11"

  replica_count       = "6"
  controller_name     = "modsec"
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name = lookup(local.live1_cert_dns_name, terraform.workspace, "")
  enable_modsec       = true
  enable_owasp        = true
  enable_latest_tls   = true

  depends_on = [module.ingress_controllers_v1]
}

module "kuberos" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberos?ref=0.4.8"

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_kubernetes_client_id     = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_id
  oidc_kubernetes_client_secret = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  cluster_address               = data.terraform_remote_state.cluster.outputs.cluster_endpoint

  depends_on = [module.ingress_controllers_v1]
}

module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=1.3.2"

  elasticsearch_host       = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  elasticsearch_audit_host = lookup(var.elasticsearch_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  dependence_prometheus    = module.monitoring.prometheus_operator_crds_status
  enable_curator_cronjob   = terraform.workspace == "live" ? true : false
}

module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=2.3.4"

  alertmanager_slack_receivers               = var.alertmanager_slack_receivers
  pagerduty_config                           = var.pagerduty_config
  cluster_domain_name                        = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id                  = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret              = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url                            = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  enable_thanos_sidecar                      = lookup(local.prod_workspace, terraform.workspace, false)
  enable_large_nodesgroup                    = terraform.workspace == "live" ? true : false
  enable_prometheus_affinity_and_tolerations = true
  enable_kibana_audit_proxy                  = terraform.workspace == "live" ? true : false
  enable_kibana_proxy                        = terraform.workspace == "live" ? true : false

  enable_thanos_helm_chart = lookup(local.prod_workspace, terraform.workspace, false)
  enable_thanos_compact    = lookup(local.manager_workspace, terraform.workspace, false)

  enable_ecr_exporter         = lookup(local.cloudwatch_workspace, terraform.workspace, false)
  enable_cloudwatch_exporter  = lookup(local.cloudwatch_workspace, terraform.workspace, false)
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "opa" {
  source     = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=0.4.3"
  depends_on = [module.monitoring.prometheus_operator_crds_status, module.modsec_ingress_controllers, module.modsec_ingress_controllers_v1, module.cert_manager]

  cluster_domain_name            = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  enable_invalid_hostname_policy = lookup(local.prod_workspace, terraform.workspace, false) ? false : true
  enable_external_dns_weight     = terraform.workspace == "live" ? true : false
  cluster_color                  = terraform.workspace == "live" ? "green" : "black"
  // integration_test_zone          = data.aws_route53_zone.integrationtest.name
}

module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.1.7"

  enable_starter_pack = lookup(local.prod_workspace, terraform.workspace, false) ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1
  ]
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=1.8.1"

  dependence_prometheus = module.monitoring.prometheus_operator_crds_status
  cluster_domain_name   = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}
