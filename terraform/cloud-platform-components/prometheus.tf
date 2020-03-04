
module "prometheus" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-prometheus?ref=0.0.5"

  alertmanager_slack_receivers = var.alertmanager_slack_receivers
  iam_role_nodes               = data.aws_iam_role.nodes.arn
  pagerduty_config             = var.pagerduty_config
  enable_ecr_exporter          = terraform.workspace == local.live_workspace ? true : false
  enable_cloudwatch_exporter   = terraform.workspace == local.live_workspace ? true : false

  dependence_deploy = null_resource.deploy
  dependence_opa    = helm_release.open-policy-agent
}

