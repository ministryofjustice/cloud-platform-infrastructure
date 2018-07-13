resource "auth0_client" "kuberos_client" {
  name                 = "Kuberos Auth (Managed by Terraform)"
  description          = "Used by k8s cluster"
  app_type             = "regular_web"
  callbacks            = ["https://login.apps.${var.tenant}.k8s.integration.dsd.io/ui"]
  custom_login_page_on = true
  is_first_party       = true

  jwt_configuration = {
    alg = "RS256"
  }
}

resource "auth0_rule" "whitelist-github-orgs" {
  name    = "whitelist-github-orgs"
  script  = "${file("whitelist-github-orgs.js")}"
  enabled = true
}

resource "auth0_rule" "whitelist-github-teams" {
  name    = "whitelist-github-teams"
  script  = "${file("whitelist-github-teams.js")}"
  enabled = true
}

resource "auth0_rule" "add-github-teams-to-oidc-group-claim" {
  name    = "add-github-teams-to-oidc-group-claim"
  script  = "${file("add-github-teams-to-oidc-group-claim.js")}"
  enabled = true
}

resource "auth0_rule" "add-github-teams-to-saml-mappings" {
  name    = "add-github-teams-to-saml-mappings"
  script  = "${file("add-github-teams-to-saml-mappings.js")}"
  enabled = true
}
