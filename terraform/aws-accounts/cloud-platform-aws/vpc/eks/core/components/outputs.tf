output "fluent_bit_irsa_arn" {
  description = "IAM Role ARN for Fluent Bit IRSA"
  value       = module.logging.fluent_bit_irsa_arn
}

output "s3_bucket_application_logs_arn" {
  description = "S3 bucket ARN for application logs"
  value       = module.logging.s3_bucket_application_logs_arn
}

output "s3_bucket_application_logs_name" {
  description = "S3 bucket name for application logs"
  value       = module.logging.s3_bucket_application_logs_name
}

output "fluent_bit_non_prod_modsec_irsa_arn" {
  description = "IAM Role ARN for Fluent Bit Non-Prod ModSecurity IRSA"
  value       = length(module.non_prod_modsec_ingress_controllers_v1) > 0 ? module.non_prod_modsec_ingress_controllers_v1[0].fluent_bit_modsec_irsa_arn : null
}

output "s3_bucket_non_prod_modsec_logs_arn" {
  description = "S3 bucket name for ModSecurity logs"
  value       = length(module.non_prod_modsec_ingress_controllers_v1) > 0 ? module.non_prod_modsec_ingress_controllers_v1[0].s3_bucket_modsec_logs_arn : null
}

output "s3_bucket_non_prod_modsec_logs_name" {
  description = "S3 bucket name for ModSecurity logs"
  value       = length(module.non_prod_modsec_ingress_controllers_v1) > 0 ? module.non_prod_modsec_ingress_controllers_v1[0].s3_bucket_modsec_logs_name : null
}

output "fluent_bit_modsec_irsa_arn" {
  description = "IAM Role ARN for Fluent Bit Non-Prod ModSecurity IRSA"
  value       = module.modsec_ingress_controllers_v1.fluent_bit_modsec_irsa_arn
}

output "s3_bucket_modsec_logs_arn" {
  description = "S3 bucket name for ModSecurity logs"
  value       = module.modsec_ingress_controllers_v1.s3_bucket_modsec_logs_arn
}

output "s3_bucket_modsec_logs_name" {
  description = "S3 bucket name for ModSecurity logs"
  value       = module.modsec_ingress_controllers_v1.s3_bucket_modsec_logs_name
}

output "alertmanager_slack_receivers" {
  description = "Alertmanager Slack Receivers configuration"
  value       = local.alertmanager_slack_receivers
  sensitive   = true
}
