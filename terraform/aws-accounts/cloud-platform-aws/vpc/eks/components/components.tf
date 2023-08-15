module "concourse" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-concourse?ref=1.18.0"

  concourse_hostname                                = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  github_auth_client_id                             = var.github_auth_client_id
  github_auth_client_secret                         = var.github_auth_client_secret
  github_org                                        = var.github_org
  github_teams                                      = var.github_teams
  tf_provider_auth0_client_id                       = var.tf_provider_auth0_client_id
  tf_provider_auth0_client_secret                   = var.tf_provider_auth0_client_secret
  cloud_platform_infrastructure_git_crypt_key       = var.cloud_platform_infrastructure_git_crypt_key
  cloud_platform_infrastructure_pr_git_access_token = var.cloud_platform_infrastructure_pr_git_access_token
  slack_hook_id                                     = var.slack_hook_id
  concourse-git-crypt                               = var.concourse-git-crypt
  environments-git-crypt                            = var.environments-git-crypt
  github_token                                      = var.github_token
  pingdom_user                                      = var.pingdom_user
  pingdom_password                                  = var.pingdom_password
  pingdom_api_key                                   = var.pingdom_api_key
  pingdom_api_token                                 = var.pingdom_api_token
  dockerhub_username                                = var.dockerhub_username
  dockerhub_password                                = var.dockerhub_password
  how_out_of_date_are_we_github_token               = var.how_out_of_date_are_we_github_token
  authorized_keys_github_token                      = var.authorized_keys_github_token
  sonarqube_token                                   = var.sonarqube_token
  sonarqube_host                                    = var.sonarqube_host
  dependence_prometheus                             = module.monitoring.prometheus_operator_crds_status
  hoodaw_host                                       = var.hoodaw_host
  hoodaw_api_key                                    = var.hoodaw_api_key
  github_actions_secrets_token                      = var.github_actions_secrets_token

  depends_on = [module.ingress_controllers_v1]
}

module "cluster_autoscaler" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-cluster-autoscaler?ref=1.4.0"

  enable_overprovision        = lookup(local.prod_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_id              = data.terraform_remote_state.cluster.outputs.cluster_id
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  # These values are for tuning live cluster overprovisioner memory and CPU requests
  live_memory_request = "1800Mi"
  live_cpu_request    = "200m"

  depends_on = [
    module.monitoring.prometheus_operator_crds_status
  ]
}

module "descheduler" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 0 : 1
  source = "github.com/ministryofjustice/cloud-platform-terraform-descheduler?ref=0.3.0"

  depends_on = [
    module.monitoring.prometheus_operator_crds_status
  ]
}
module "cert_manager" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=1.7.0"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])

  # Requiring Prometheus taints the default cert null_resource on any monitoring upgrade,
  # but cluster creation fails without, so will have to be temporarily disabled when upgrading
  dependence_prometheus = module.monitoring.prometheus_operator_crds_status

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.11.1"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzones           = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])
  domain_filters      = lookup(local.domain_filters, terraform.workspace, local.domain_filters["default"])

  dependence_prometheus       = module.monitoring.prometheus_operator_crds_status
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "external_secrets_operator" {
  source                      = "github.com/ministryofjustice/cloud-platform-terraform-external-secrets-operator?ref=0.0.1"
  dependence_prometheus       = module.monitoring.prometheus_operator_crds_status
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  secrets_prefix              = terraform.workspace
}
module "ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.3.0"

  replica_count       = "12"
  controller_name     = "default"
  enable_latest_tls   = true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name = lookup(local.live1_cert_dns_name, terraform.workspace, "")

  # Enable this when we remove the module "ingress_controllers"
  enable_external_dns_annotation = true

  # Dependency on this ingress_controllers module as IC namespace and default certificate created in this module
  # This dependency will go away once "module.ingress_controllers" is removed.
  dependence_certmanager = module.cert_manager.helm_cert_manager_status
}

module "modsec_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.3.0"

  replica_count          = "12"
  controller_name        = "modsec"
  cluster_domain_name    = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster        = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name    = lookup(local.live1_cert_dns_name, terraform.workspace, "")
  enable_modsec          = true
  enable_owasp           = true
  enable_latest_tls      = true
  dependence_certmanager = "ignore"
  depends_on             = [module.ingress_controllers_v1]
}

module "kuberos" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberos?ref=0.5.2"

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_kubernetes_client_id     = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_id
  oidc_kubernetes_client_secret = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  cluster_address               = data.terraform_remote_state.cluster.outputs.cluster_endpoint

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1
  ]
}

module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=1.9.9"

  elasticsearch_host              = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  elasticsearch_modsec_audit_host = lookup(var.elasticsearch_modsec_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  dependence_prometheus           = module.monitoring.prometheus_operator_crds_status
}

module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=2.9.3"

  alertmanager_slack_receivers               = local.enable_alerts ? var.alertmanager_slack_receivers : [{ severity = "dummy", webhook = "https://dummy.slack.com", channel = "#dummy-alarms" }]
  pagerduty_config                           = local.enable_alerts ? var.pagerduty_config : "dummy"
  cluster_domain_name                        = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id                  = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret              = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url                            = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  enable_thanos_sidecar                      = lookup(local.prod_2_workspace, terraform.workspace, false)
  enable_large_nodesgroup                    = lookup(local.live_workspace, terraform.workspace, false)
  enable_prometheus_affinity_and_tolerations = true
  enable_kibana_proxy                        = lookup(local.live_workspace, terraform.workspace, false)
  kibana_upstream                            = format("%s://%s", "https", lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch"))

  enable_thanos_helm_chart = lookup(local.prod_2_workspace, terraform.workspace, false)
  enable_thanos_compact    = lookup(local.manager_workspace, terraform.workspace, false)

  enable_ecr_exporter           = lookup(local.live_workspace, terraform.workspace, false)
  enable_cloudwatch_exporter    = lookup(local.live_workspace, terraform.workspace, false)
  eks_cluster_oidc_issuer_url   = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  dependence_ingress_controller = [module.modsec_ingress_controllers_v1.helm_nginx_ingress_status]

  depends_on = [module.eks_csi]
}

module "gatekeeper" {
  source     = "github.com/ministryofjustice/cloud-platform-terraform-gatekeeper?ref=1.5.4"
  depends_on = [module.monitoring, module.modsec_ingress_controllers_v1, module.cert_manager]

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
    warn_service_account_secret_delete = false
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
  audit_mem_limit      = terraform.workspace == "live" ? "4Gi" : "1Gi"
  audit_mem_req        = terraform.workspace == "live" ? "1Gi" : "512Mi"
}

module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.2.1"

  enable_starter_pack = lookup(local.prod_2_workspace, terraform.workspace, false) ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1
  ]
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=1.11.0"

  enable_velero               = lookup(local.prod_2_workspace, terraform.workspace, false)
  dependence_prometheus       = module.monitoring.prometheus_operator_crds_status
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  restic_cpu_requests         = "2m"
}

module "kuberhealthy" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberhealthy?ref=1.2.0"

  dependence_prometheus = module.monitoring.prometheus_operator_crds_status
}

module "trivy-operator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-trivy-operator?ref=0.7.2"

  depends_on = [
    module.monitoring.prometheus_operator_crds_status
  ]

  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  # job concurrency limit and scanner report ttl need balancing to
  # ensure report completeness across the cluster
  job_concurrency_limit = 2
  scanner_report_ttl    = "48h"

  scan_job_timeout    = "10m"
  trivy_timeout       = "10m0s"
  severity_list       = "HIGH,CRITICAL"
  enable_trivy_server = "true"
}
