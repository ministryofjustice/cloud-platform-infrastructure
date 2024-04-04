module "concourse" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-concourse?ref=1.23.4"

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
  slack_bot_token                                   = var.slack_bot_token
  slack_webhook_url                                 = var.slack_webhook_url
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

  hoodaw_host                  = var.hoodaw_host
  hoodaw_api_key               = var.hoodaw_api_key
  github_actions_secrets_token = var.github_actions_secrets_token
  hoodaw_irsa_enabled          = var.hoodaw_irsa_enabled
  eks_cluster_name             = terraform.workspace

  depends_on = [module.monitoring, module.ingress_controllers_v1]
}

module "cluster_autoscaler" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-cluster-autoscaler?ref=1.8.0"

  enable_overprovision        = lookup(local.prod_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_id              = data.terraform_remote_state.cluster.outputs.cluster_id
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  # These values are for tuning live cluster overprovisioner memory and CPU requests
  live_memory_request = "1800Mi"
  live_cpu_request    = "200m"

  depends_on = [
    module.monitoring
  ]
}

module "descheduler" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 0 : 1
  source = "github.com/ministryofjustice/cloud-platform-terraform-descheduler?ref=0.6.0"

  depends_on = [
    module.monitoring
  ]
}

module "cert_manager" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=1.10.0"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  depends_on = [module.monitoring.prometheus_operator_crds_status]
}

module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.15.0"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzones           = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])
  domain_filters      = lookup(local.domain_filters, terraform.workspace, local.domain_filters["default"])


  # For tuning external_dns config for production vs test clusters
  is_live_cluster = lookup(local.prod_workspace, terraform.workspace, false) || terraform.workspace == "live-2"

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  depends_on = [module.monitoring.prometheus_operator_crds_status]
}

module "external_secrets_operator" {
  source                      = "github.com/ministryofjustice/cloud-platform-terraform-external-secrets-operator?ref=0.1.0"
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  secrets_prefix              = terraform.workspace

  depends_on = [
    module.gatekeeper,
    module.monitoring.prometheus_operator_crds_status
  ]
}
module "ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.8.5"

  replica_count       = lookup(local.live_workspace, terraform.workspace, false) ? "30" : "3"
  controller_name     = "default"
  enable_latest_tls   = true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name = lookup(local.live1_cert_dns_name, terraform.workspace, "")

  # Enable this when we remove the module "ingress_controllers"
  enable_external_dns_annotation = true

  memory_requests = lookup(local.live_workspace, terraform.workspace, false) ? "5Gi" : "512Mi"
  memory_limits   = lookup(local.live_workspace, terraform.workspace, false) ? "20Gi" : "2Gi"

  depends_on = [module.cert_manager.helm_cert_manager_status]
}

module "production_only_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.8.5"
  count  = lookup(local.live_workspace, terraform.workspace, false) ? 1 : 0

  replica_count            = "6"
  controller_name          = "production-only"
  enable_cross_zone_lb     = false
  upstream_keepalive_time  = "120s"
  enable_latest_tls        = true
  proxy_response_buffering = "on"
  cluster_domain_name      = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster          = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name      = lookup(local.live1_cert_dns_name, terraform.workspace, "")

  # Enable this when we remove the module "ingress_controllers"
  enable_external_dns_annotation = true

  memory_requests = "5Gi"
  memory_limits   = "20Gi"

  depends_on = [module.cert_manager.helm_cert_manager_status]
}


module "modsec_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.8.5"

  replica_count       = lookup(local.live_workspace, terraform.workspace, false) ? "12" : "3"
  controller_name     = "modsec"
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name = lookup(local.live1_cert_dns_name, terraform.workspace, "")
  enable_modsec       = true
  enable_owasp        = true
  enable_latest_tls   = true
  memory_requests     = lookup(local.live_workspace, terraform.workspace, false) ? "3Gi" : "512Mi"
  memory_limits       = lookup(local.live_workspace, terraform.workspace, false) ? "20Gi" : "2Gi"

  opensearch_modsec_audit_host = lookup(var.elasticsearch_modsec_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  cluster                      = terraform.workspace
  fluent_bit_version           = "2.2.1-amd64"

  depends_on = [module.ingress_controllers_v1]
}

module "kuberos" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberos?ref=0.5.5"

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_kubernetes_client_id     = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_id
  oidc_kubernetes_client_secret = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  cluster_address               = data.terraform_remote_state.cluster.outputs.cluster_endpoint

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1,
    module.production_only_ingress_controllers_v1

  ]
}

module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=1.13.0"

  opensearch_app_host = lookup(var.opensearch_app_host_map, terraform.workspace, "placeholder-opensearch")
  elasticsearch_host  = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")

  depends_on = [module.monitoring.prometheus_operator_crds_status]
}

module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=3.6.0"

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

  enable_ecr_exporter         = lookup(local.live_workspace, terraform.workspace, false)
  enable_cloudwatch_exporter  = lookup(local.live_workspace, terraform.workspace, false)
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  depends_on = [module.eks_csi]
}

module "gatekeeper" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-gatekeeper?ref=1.12.0"

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
    lock_priv_capabilities = true,
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
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.2.5"

  enable_starter_pack = lookup(local.prod_2_workspace, terraform.workspace, false) ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1,
    module.gatekeeper
  ]
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=2.2.0"

  enable_velero               = lookup(local.prod_2_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  node_agent_cpu_requests     = "2m"

  depends_on = [module.monitoring.prometheus_operator_crds_status]
}

module "kuberhealthy" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberhealthy?ref=1.4.0"

  cluster_env = terraform.workspace

  depends_on = [
    module.monitoring.prometheus_operator_crds_status,
    module.velero,
    module.gatekeeper
  ]
}

module "trivy-operator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-trivy-operator?ref=0.8.2"

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
