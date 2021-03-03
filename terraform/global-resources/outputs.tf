output "k8s_oidc_group_claim_domain" {
  value = auth0_rule_config.k8s-oidc-group-claim-domain.value
}

output "saml_login_page" {
  value = "https://${local.auth0_tenant_domain}/samlp/${auth0_client.saml.client_id}"
}

