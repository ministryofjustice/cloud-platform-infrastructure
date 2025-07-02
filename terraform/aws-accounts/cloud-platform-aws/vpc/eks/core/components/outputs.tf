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
