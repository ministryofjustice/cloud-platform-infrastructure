resource "aws_acm_certificate" "apps" {
  domain_name       = "*.apps.${var.cluster_base_domain_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "apps_cert_validation" {
  name    = aws_acm_certificate.apps.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.apps.domain_validation_options[0].resource_record_type
  zone_id = var.dns_zone_id
  records = [aws_acm_certificate.apps.domain_validation_options[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "apps" {
  certificate_arn         = aws_acm_certificate.apps.arn
  validation_record_fqdns = [aws_route53_record.apps_cert_validation.fqdn]
}

