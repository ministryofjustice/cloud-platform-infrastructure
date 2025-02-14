output "slack_sns_topic" {
  description = "Slack integration sns topic name"
  value       = module.baselines.slack_sns_topic
}

output "cp_zone_id" {
  value       = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  description = "This output is very important, it is widely used from kops/eks clusters"
}

output "click_here_to_login" {
  value       = module.sso.saml_login_page
  description = "SSO login page for Cloud Platform"
}

output "github_teams_filter_api_key" {
  value       = module.sso.github_teams_filter_api_key
  description = "API key for the GitHub teams filter API"
}