# output "k8s_zone_id" {
#   value = aws_route53_zone.k8s_integration_dsd_io.zone_id
# }

# output "k8s_domain_name" {
#   value = aws_route53_zone.k8s_integration_dsd_io.name
# }

output "cp_zone_id" {
  value = aws_route53_zone.cloud-platform_justice_gov_uk.zone_id
}

output "cp_domain_name" {
  value = aws_route53_zone.cloud-platform_justice_gov_uk.name
}

# output "kops_state_store" {
#   value = aws_s3_bucket.kops_state_store.bucket
# }

output "k8s_oidc_group_claim_domain" {
  value = auth0_rule_config.k8s-oidc-group-claim-domain.value
}

output "saml_login_page" {
  value = "https://${local.auth0_tenant_domain}/samlp/${auth0_client.saml.client_id}"
}

