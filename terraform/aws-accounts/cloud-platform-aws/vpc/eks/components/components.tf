module "concourse" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 1 : 0
  source = "github.com/ministryofjustice/cloud-platform-terraform-concourse?ref=1.11.1"

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
  source = "github.com/ministryofjustice/cloud-platform-terraform-cluster-autoscaler?ref=1.1.0"

  enable_overprovision        = lookup(local.prod_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_id              = data.terraform_remote_state.cluster.outputs.cluster_id
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  depends_on = [
    module.monitoring.prometheus_operator_crds_status
  ]
}

module "descheduler" {
  count  = lookup(local.manager_workspace, terraform.workspace, false) ? 0 : 1
  source = "github.com/ministryofjustice/cloud-platform-terraform-descheduler?ref=0.2.0"

  depends_on = [
    module.monitoring.prometheus_operator_crds_status
  ]
}
module "cert_manager" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=1.6.0"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])

  # Requiring Prometheus taints the default cert null_resource on any monitoring upgrade,
  # but cluster creation fails without, so will have to be temporarily disabled when upgrading
  dependence_prometheus = module.monitoring.prometheus_operator_crds_status
  dependence_opa        = "ignore"

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.10.0"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzones           = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])
  domain_filters      = lookup(local.domain_filters, terraform.workspace, local.domain_filters["default"])

  dependence_prometheus       = module.monitoring.prometheus_operator_crds_status
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}


module "ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.2.0"

  replica_count       = "6"
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
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.2.1"

  replica_count          = "6"
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
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberos?ref=0.5.0"

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
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=1.4.0"

  elasticsearch_host       = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  elasticsearch_audit_host = lookup(var.elasticsearch_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch")
  dependence_prometheus    = module.monitoring.prometheus_operator_crds_status
  enable_curator_cronjob   = terraform.workspace == "live" ? true : false
}

module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=2.6.0"

  alertmanager_slack_receivers               = local.enable_alerts ? var.alertmanager_slack_receivers : [{ severity = "dummy", webhook = "https://dummy.slack.com", channel = "#dummy-alarms" }]
  pagerduty_config                           = local.enable_alerts ? var.pagerduty_config : "dummy"
  cluster_domain_name                        = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id                  = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret              = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url                            = data.terraform_remote_state.cluster.outputs.oidc_issuer_url
  enable_thanos_sidecar                      = lookup(local.prod_2_workspace, terraform.workspace, false)
  enable_large_nodesgroup                    = lookup(local.live_workspace, terraform.workspace, false)
  enable_prometheus_affinity_and_tolerations = true
  enable_kibana_audit_proxy                  = terraform.workspace == "live" ? true : false
  enable_kibana_proxy                        = lookup(local.live_workspace, terraform.workspace, false)
  kibana_upstream                            = format("%s://%s", "https", lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch"))
  kibana_audit_upstream                      = format("%s://%s", "https", lookup(var.elasticsearch_audit_hosts_maps, terraform.workspace, "placeholder-elasticsearch"))

  enable_thanos_helm_chart = lookup(local.prod_2_workspace, terraform.workspace, false)
  enable_thanos_compact    = lookup(local.manager_workspace, terraform.workspace, false)

  enable_ecr_exporter           = lookup(local.live_workspace, terraform.workspace, false)
  enable_cloudwatch_exporter    = lookup(local.live_workspace, terraform.workspace, false)
  eks_cluster_oidc_issuer_url   = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  dependence_ingress_controller = [module.modsec_ingress_controllers_v1.helm_nginx_ingress_status]

  depends_on = [module.eks_csi]
}

module "opa" {
  source     = "github.com/ministryofjustice/cloud-platform-terraform-opa?ref=0.5.0"
  depends_on = [module.monitoring, module.modsec_ingress_controllers_v1, module.cert_manager]

  cluster_domain_name            = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  enable_invalid_hostname_policy = lookup(local.prod_2_workspace, terraform.workspace, false) ? false : true
  # Validation for external_dns_weight annotation is enabled only on the "live" cluster
  enable_external_dns_weight = terraform.workspace == "live" ? true : false
  cluster_color              = terraform.workspace == "live" ? "green" : "black"
  integration_test_zone      = data.aws_route53_zone.integrationtest.name
}

module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.2.0"

  enable_starter_pack = lookup(local.prod_2_workspace, terraform.workspace, false) ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1
  ]
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=1.10.0"

  enable_velero               = lookup(local.prod_2_workspace, terraform.workspace, false)
  dependence_prometheus       = module.monitoring.prometheus_operator_crds_status
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "kuberhealthy" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberhealthy?ref=1.1.0"

  dependence_prometheus = module.monitoring.prometheus_operator_crds_status
}

module "trivy-operator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-trivy-operator?ref=0.4.0"

  depends_on = [
    module.monitoring.prometheus_operator_crds_status
  ]

  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  dockerhub_username = var.dockerhub_username
  dockerhub_password = var.dockerhub_password
  github_token       = var.github_token

  job_concurrency_limit = 2
  scan_job_timeout      = "10m"
  trivy_timeout         = "10m0s"
  severity_list         = "HIGH,CRITICAL"
  enable_trivy_server   = "true"
}

