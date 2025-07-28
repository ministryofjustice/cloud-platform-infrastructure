module "non_prod_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.14.7"
  count  = terraform.workspace == "live" ? 1 : 0

  replica_count            = "6"
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

  default_tags = local.default_tags

  depends_on = [
    module.label_pods_controller
  ]
}

module "non_prod_modsec_ingress_controllers_v1" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ingress-controller?ref=1.15.3"

  count = terraform.workspace == "live" ? 1 : 0

  replica_count            = "6"
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

module "kuberos" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kuberos?ref=0.7.0"

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
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=1.26.7"

  opensearch_app_host = lookup(var.opensearch_app_host_map, terraform.workspace, "placeholder-opensearch")
  elasticsearch_host  = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")

  depends_on = [
    module.label_pods_controller
  ]

  # Required variables for tags in S3-Bucket submodule
  business_unit = local.default_tags["business-unit"]
  application   = local.default_tags["application"]
  is_production = local.default_tags["is-production"]
  team_name     = local.default_tags["owner"]

}

module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=3.26.0"

  alertmanager_slack_receivers  = local.enable_alerts ? var.alertmanager_slack_receivers : [{ severity = "dummy", webhook = "https://dummy.slack.com", channel = "#dummy-alarms" }]
  pagerduty_config              = local.enable_alerts ? data.aws_ssm_parameter.components["pagerduty_config"].value : "dummy"
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
  aws_subnet_exporter_image_tag = "c8dd738558837b9eef99858c3eaeeb70957b90b0"

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1
  ]
}

module "starter_pack" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-starter-pack?ref=0.3.0"

  enable_starter_pack = lookup(local.prod_2_workspace, terraform.workspace, false) ? false : true
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name

  depends_on = [
    module.ingress_controllers_v1,
    module.modsec_ingress_controllers_v1
  ]
}

module "velero" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=2.5.1"

  enable_velero               = lookup(local.prod_2_workspace, terraform.workspace, false)
  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
  node_agent_cpu_requests     = "2m"

  depends_on = [
    module.label_pods_controller
  ]
}

module "trivy-operator" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-trivy-operator?ref=0.13.0"

  cluster_domain_name         = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url

  # job concurrency limit and scanner report ttl need balancing to
  # ensure report completeness across the cluster
  job_concurrency_limit = 4
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
  source = "github.com/ministryofjustice/cloud-platform-github-teams-filter?ref=1.2.0"

  count          = terraform.workspace == "live" ? 1 : 0
  chart_version  = "1.0.1"
  ecr_url        = "754256621582.dkr.ecr.eu-west-2.amazonaws.com/webops/cloud-platform-github-teams-filter"
  image_tag      = "7d8e836a0685bd50fcc23f3b824a0aed892cf9b4"
  replica_count  = 2
  hostname       = "github-teams-filter.apps.${data.aws_route53_zone.selected.name}"
  filter_api_key = data.terraform_remote_state.account.outputs.github_teams_filter_api_key

}
