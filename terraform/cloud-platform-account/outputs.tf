output "slack_sns_topic" {
  description = "Slack integration sns topic name"
  value       = module.baselines.slack_sns_topic
}

output "cp_zone_id" {
  value       = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  description = "This output is very important, it is widely used from kops/eks clusters"
}
