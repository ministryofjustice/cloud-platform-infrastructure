
module "prometheus" {
  source = "/Users/mogaal/workspace/github/ministryofjustice/cloud-platform-terraform-prometheus"

  alertmanager_slack_receivers = var.alertmanager_slack_receivers
  iam_role_nodes               = data.aws_iam_role.nodes.arn
  pagerduty_config             = var.pagerduty_config
  enable_thanos                = true

  dependence_deploy = null_resource.deploy
  dependence_opa    = helm_release.open-policy-agent
}

