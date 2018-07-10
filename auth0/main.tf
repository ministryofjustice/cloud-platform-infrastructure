resource "auth0_client" "kuberos_client" {
  name = "Kuberos Auth (Managed by Terraform)"
  description = "Used by k8s cluster"
  app_type = "native"
  custom_login_page_on = true
  is_first_party = true
}

resource "auth0_rule" "whitelist-github-orgs" {
  name = "whitelist-github-orgs"
  script = "${file("whitelist-github-orgs.js")}"
  enabled = true
}

resource "auth0_rule" "whitelist-github-teams" {
  name = "whitelist-github-teams"
  script = "${file("whitelist-github-teams.js")}"
  enabled = true
}

resource "auth0_rule" "map-github-user-and-group-to-k8s" {
  name = "map-github-user-and-group-to-k8s"
  script = "${file("map-github-user-and-group-to-k8s.js")}"
  enabled = true
}
