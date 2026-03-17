####################################################
# SSM Parameters for infrastructure/account layer #
####################################################

locals {
  ssm_parameters = [
    "cortex_xsiam_endpoint"
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

# SSM parameter for Chainguard docker registry credentials
resource "aws_ssm_parameter" "chainguard_registry_credentials" {
  name        = "/cloud-platform/infrastructure/account/chainguard_registry_credentials"
  type        = "SecureString"
  value       = "PLACEHOLDER"
  description = "infrastructure/account terraform secret: chainguard_registry_credentials"

  overwrite = true
  lifecycle {
    ignore_changes = [value]
  }
}