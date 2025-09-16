module "monitoring" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=3.30.3"

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
