output "fluent_bit_irsa_arn" {
  description = "IAM Role ARN for Fluent Bit IRSA"
  value       = module.logging.fluent_bit_irsa_arn
}
