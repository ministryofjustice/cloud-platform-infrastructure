####################################################
# SSM Parameters for infrastructure/account layer #
####################################################

locals {
  ssm_parameters = [
    "cortex_xsiam_endpoint"
  ]

  github_concourse_bot = [
    "app_id",
    "installation_id",
    "pem_file"
  ]
}

# Account SSM Parameters creation
resource "aws_ssm_parameter" "account" {
  for_each = toset(local.ssm_parameters)

  name        = "/cloud-platform/infrastructure/account/${each.value}"
  type        = "SecureString"
  value       = "PLACEHOLDER"
  description = "infrastructure/account terraform secret: ${each.value}"

  overwrite = true

  lifecycle {
    ignore_changes = [value]
  }
}

# Data blocks for SSM parameter lookup in all workspaces
data "aws_ssm_parameter" "account" {
  for_each = toset(local.ssm_parameters)

  name = "/cloud-platform/infrastructure/account/${each.value}"

}

resource "aws_ssm_parameter" "github_concourse_bot_app" {
  for_each = toset(local.github_concourse_bot)

  name        = "/cloud-platform/infrastructure/account/github_cloud_platform_concourse_bot_app/${each.value}"
  type        = "SecureString"
  value       = "PLACEHOLDER"
  description = "infrastructure/account terraform secret: github_cloud_platform _concourse_bot_app/${each.value}"

  overwrite = true

  lifecycle {
    ignore_changes = [value]
  }
}