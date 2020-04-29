
module "prometheus" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-monitoring?ref=0.2.0"

  alertmanager_slack_receivers               = var.alertmanager_slack_receivers
  iam_role_nodes                             = data.aws_iam_role.nodes.arn
  pagerduty_config                           = var.pagerduty_config
  enable_ecr_exporter                        = terraform.workspace == local.live_workspace ? true : false
  enable_cloudwatch_exporter                 = terraform.workspace == local.live_workspace ? true : false
  enable_thanos_helm_chart                   = false
  enable_prometheus_affinity_and_tolerations = terraform.workspace == local.live_workspace ? true : false

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  oidc_components_client_id     = data.terraform_remote_state.cluster.outputs.oidc_components_client_id
  oidc_components_client_secret = data.terraform_remote_state.cluster.outputs.oidc_components_client_secret
  oidc_issuer_url               = data.terraform_remote_state.cluster.outputs.oidc_issuer_url

  dependence_deploy = null_resource.deploy
  dependence_opa    = module.opa.helm_opa_status
}

