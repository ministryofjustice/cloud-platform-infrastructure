resource "auth0_rule" "allow-github-orgs" {
  name = "allow-github-orgs"
  script = file(
    "${path.module}/resources/auth0-rules/allow-github-orgs.js",
  )
  order   = 10
  enabled = false
}

resource "auth0_rule" "add-github-teams-to-oidc-group-claim" {
  name = "add-github-teams-to-oidc-group-claim"
  script = file(
    "${path.module}/resources/auth0-rules/add-github-teams-to-oidc-group-claim.js",
  )
  order   = 30
  enabled = false
}

resource "auth0_rule_config" "aws-account-id" {
  key   = "AWS_ACCOUNT_ID"
  value = data.aws_caller_identity.cloud-platform.account_id
}

resource "auth0_rule_config" "k8s-oidc-group-claim-domain" {
  key   = "K8S_OIDC_GROUP_CLAIM_DOMAIN"
  value = "https://k8s.integration.dsd.io/groups"
}

module "global_auth0" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-global-resources-auth0?ref=2.1.3"

  auth0_tenant_domain = local.auth0_tenant_domain
  auth0_groupsClaim   = local.auth0_groupsClaim
}
