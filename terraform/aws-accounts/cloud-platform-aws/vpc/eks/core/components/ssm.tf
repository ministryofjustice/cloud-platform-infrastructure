##############################################
# SSM Parameters for components credentials #
##############################################

locals {
  ssm_parameters = [
    "github_auth_client_id",
    "github_auth_client_secret",
    "github_org",
    "github_teams",
    "tf_provider_auth0_client_id",
    "tf_provider_auth0_client_secret",
    "cloud_platform_infrastructure_git_crypt_key",
    "slack_hook_id",
    "slack_bot_token",
    "slack_webhook_url",
    "concourse_git_crypt",
    "environments_git_crypt",
    "cloud_platform_infrastructure_pr_git_access_token",
    "github_token",
    "pingdom_user",
    "pingdom_password",
    "pingdom_api_key",
    "pingdom_api_token",
    "dockerhub_username",
    "dockerhub_password",
    "how_out_of_date_are_we_github_token",
    "authorized_keys_github_token",
    "hoodaw_host",
    "hoodaw_api_key",
    "github_actions_secrets_token",
    "pagerduty_config"
  ]
}

# Components SSM Parameters are managed in live workspace
resource "aws_ssm_parameter" "components" {
  for_each = terraform.workspace == "live" ? toset(local.ssm_parameters) : toset([])

  name        = "/cloud-platform/infrastructure/components/${each.value}"
  type        = "SecureString"
  value       = "PLACEHOLDER"
  description = "components.tf secret: ${each.value}"

  lifecycle {
    ignore_changes = [value]
  }
}

# Data blocks for SSM parameter lookup in all workspaces
data "aws_ssm_parameter" "components" {
  for_each = toset(local.ssm_parameters)

  name = "/cloud-platform/infrastructure/components/${each.value}"
}
