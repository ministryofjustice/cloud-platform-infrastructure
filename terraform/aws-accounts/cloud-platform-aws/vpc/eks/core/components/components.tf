module "concourse" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-concourse?ref=1.30.0"

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
  teams_filter_api_key                              = data.terraform_remote_state.account.outputs.github_teams_filter_api_key
  limit_active_tasks                                = 2
  environments_live_reports_s3_bucket               = data.terraform_remote_state.account.outputs.concourse_environments_live-reports_bucket

  hoodaw_host                  = var.hoodaw_host
  hoodaw_api_key               = var.hoodaw_api_key
  github_actions_secrets_token = var.github_actions_secrets_token
  hoodaw_irsa_enabled          = var.hoodaw_irsa_enabled
  eks_cluster_name             = terraform.workspace

  depends_on = [
    module.monitoring,
    module.ingress_controllers_v1
  ]
}

module "cluster_autoscaler" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-cluster-autoscaler?ref=1.12.0"

  enable_overprovision        = lookup(local.prod_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_id              = data.terraform_remote_state.cluster.outputs.cluster_id
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  # These values are for tuning live cluster overprovisioner memory and CPU requests
  live_memory_request = "1800Mi"
  live_cpu_request    = "200m"

  depends_on = [
    module.label_pods_controller,
    module.monitoring
  ]
}

module "descheduler" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 0 : 1
  source = "github.com/ministryofjustice/cloud-platform-terraform-descheduler?ref=0.9.1"

  depends_on = [
    module.monitoring,
    module.label_pods_controller
  ]
}

module "label_pods_controller" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-label-pods?ref=1.1.4"

  chart_version = "1.0.2"
  # https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/main/terraform/aws-accounts/cloud-platform-aws/account/ecr.tf
  ecr_url   = "754256621582.dkr.ecr.eu-west-2.amazonaws.com/webops/cloud-platform-terraform-label-pods"
  image_tag = "1.1.4"
}


module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.18.0"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzones           = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])
  domain_filters      = lookup(local.domain_filters, terraform.workspace, local.domain_filters["default"])


  # For tuning external_dns config for production vs test clusters
  is_live_cluster = lookup(local.prod_workspace, terraform.workspace, false) || terraform.workspace == "live-2"

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "external_secrets_operator" {
  source                      = "github.com/ministryofjustice/cloud-platform-terraform-external-secrets-operator?ref=0.1.0"
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  secrets_prefix              = terraform.workspace

  depends_on = [
    module.label_pods_controller
  ]
}

module "ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.10.4"

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

  memory_requests = lookup(local.live_workspace, terraform.workspace, false) ? "5Gi" : "512Mi"
  memory_limits   = lookup(local.live_workspace, terraform.workspace, false) ? "20Gi" : "2Gi"

  depends_on = [
    module.label_pods_controller
  ]
}

module "non_prod_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.10.4"
  count  = terraform.workspace == "live" ? 1 : 0

  replica_count            = "3"
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

  depends_on = [
    module.label_pods_controller
  ]
}

module "non_prod_modsec_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.10.4"

  count = terraform.workspace == "live" ? 1 : 0

  replica_count            = "3"
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

  opensearch_modsec_audit_host = lookup(var.elasticsearch_modsec_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  cluster                      = terraform.workspace
  fluent_bit_version           = "3.0.2-amd64"

  depends_on = [module.ingress_controllers_v1]
}

module "modsec_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.10.4"


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

  opensearch_modsec_audit_host = lookup(var.elasticsearch_modsec_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  cluster                      = terraform.workspace
  fluent_bit_version           = "3.0.2-amd64"

  depends_on = [module.ingress_controllers_v1]
}

module "kuberos" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberos?ref=0.6.2"

  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_kubernetes_client_id     = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_id
  oidc_kubernetes_client_secret = data.terraform_remote_state.cluster.outputs.oidc_kubernetes_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  cluster_address               = data.terraform_remote_state.cluster.outputs.cluster_endpoint
  image_tag                     = "2.7.0"
  replica_count                 = 8

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1,
    module.non_prod_ingress_controllers_v1
  ]
}

module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=1.20.0"

  opensearch_app_host = lookup(var.opensearch_app_host_map, terraform.workspace, "placeholder-opensearch")
  elasticsearch_host  = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")

  depends_on = [
    module.label_pods_controller
  ]
}

module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=3.20.0"

  alertmanager_slack_receivers  = local.enable_alerts ? var.alertmanager_slack_receivers : [{ severity = "dummy", webhook = "https://dummy.slack.com", channel = "#dummy-alarms" }]
  pagerduty_config              = local.enable_alerts ? var.pagerduty_config : "dummy"
  cluster_domain_name           = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  enable_thanos_sidecar         = lookup(local.prod_2_workspace, terraform.workspace, false)
  enable_large_nodesgroup       = lookup(local.live_workspace, terraform.workspace, false)

  # The largegroup cpu and memory requests are valid only if the large_nodegroup is enabled.
  large_nodesgroup_cpu_requests              = terraform.workspace == "live" ? "14000m" : "1300m"
  large_nodesgroup_memory_requests           = terraform.workspace == "live" ? "180000Mi" : "14000Mi"
  enable_prometheus_affinity_and_tolerations = true

  enable_thanos_helm_chart   = lookup(local.prod_2_workspace, terraform.workspace, false)
  enable_thanos_compact      = lookup(local.manager_workspace, terraform.workspace, false)
  thanos_query_replica_count = 1

  enable_ecr_exporter           = lookup(local.live_workspace, terraform.workspace, false)
  enable_cloudwatch_exporter    = lookup(local.live_workspace, terraform.workspace, false)
  enable_rds_exporter           = terraform.workspace == "live"
  enable_subnet_exporter        = terraform.workspace == "live"
  aws_subnet_exporter_image_tag = "d79d5d75cbdcd442b9a04e17269ece994b3b551d"

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1
  ]
}

module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.2.6"

  enable_starter_pack = lookup(local.prod_2_workspace, terraform.workspace, false) ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1
  ]
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=2.4.1"

  enable_velero               = lookup(local.prod_2_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  node_agent_cpu_requests     = "2m"

  depends_on = [
    module.label_pods_controller
  ]
}

module "trivy-operator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-trivy-operator?ref=0.10.0"

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

  depends_on = [
    module.label_pods_controller
  ]
}

module "github-teams-filter" {
  source = "github.com/ministryofjustice/cloud-platform-github-teams-filter?ref=1.1.1"

  count          = terraform.workspace == "live" ? 1 : 0
  chart_version  = "1.0.1"
  ecr_url        = "754256621582.dkr.ecr.eu-west-2.amazonaws.com/webops/cloud-platform-github-teams-filter"
  image_tag      = "7d8e836a0685bd50fcc23f3b824a0aed892cf9b4"
  replica_count  = 2
  hostname       = "github-teams-filter.apps.${data.aws_route53_zone.selected.name}"
  filter_api_key = data.terraform_remote_state.account.outputs.github_teams_filter_api_key

}

