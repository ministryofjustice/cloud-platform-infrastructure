resource "auth0_rule" "whitelist-github-orgs" {
  name    = "whitelist-github-orgs"
  script  = "${file("${path.module}/resources/auth0-rules/whitelist-github-orgs.js")}"
  order   = 10
  enabled = true
}

resource "auth0_rule" "whitelist-github-teams" {
  name    = "whitelist-github-teams"
  script  = "${file("${path.module}/resources/auth0-rules/whitelist-github-teams.js")}"
  order   = 20
  enabled = true
}

resource "auth0_rule" "add-github-teams-to-oidc-group-claim" {
  name    = "add-github-teams-to-oidc-group-claim"
  script  = "${file("${path.module}/resources/auth0-rules/add-github-teams-to-oidc-group-claim.js")}"
  order   = 30
  enabled = true
}

resource "auth0_rule" "add-github-teams-to-saml-mappings" {
  name    = "add-github-teams-to-saml-mappings"
  script  = "${file("${path.module}/resources/auth0-rules/add-github-teams-to-saml-mappings.js")}"
  order   = 40
  enabled = true
}

resource "auth0_rule_config" "aws-account-id" {
  key   = "AWS_ACCOUNT_ID"
  value = "${data.aws_caller_identity.cloud-platform.account_id}"
}

resource "auth0_rule_config" "k8s-oidc-group-claim-domain" {
  key   = "K8S_OIDC_GROUP_CLAIM_DOMAIN"
  value = "https://k8s.integration.dsd.io/groups"
}

resource "auth0_rule_config" "aws-saml-provider-name" {
  key   = "AWS_SAML_PROVIDER_NAME"
  value = "auth0"
}
