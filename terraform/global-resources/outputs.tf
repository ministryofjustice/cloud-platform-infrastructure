output "k8s_oidc_group_claim_domain" {
  value     = auth0_rule_config.k8s-oidc-group-claim-domain.value
  sensitive = true
}
