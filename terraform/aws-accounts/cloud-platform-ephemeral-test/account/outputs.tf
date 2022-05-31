output "route53_root_domain_dns" {
  value = aws_route53_zone.aws_account_hostzone_id.name_servers
}

output "kops_state_s3_bucket_name" {
  value = module.kops_state_backend.bucket_name
}

output "aws_account_hostzone_id" {
  value = aws_route53_zone.aws_account_hostzone_id.zone_id
}

output "aws_account_hostzone_name" {
  value = aws_route53_zone.aws_account_hostzone_id.name
}

output "baselines_logging_buckets" {
  value = module.baselines.logging_buckets
}

output "click_here_to_login" {
  value = module.sso.saml_login_page
}
