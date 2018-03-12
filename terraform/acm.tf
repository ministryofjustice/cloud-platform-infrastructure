resource "aws_acm_certificate" "apps" {
  domain_name = "*.apps.${local.sandbox_domain_name}"
  validation_method = "DNS"
}

resource "aws_acm_certificate" "non-prod" {
  domain_name = "*.apps.${local.non-prod_domain_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "apps_cert_validation" {
  name = "${aws_acm_certificate.apps.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.apps.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.sandbox.id}"
  records = ["${aws_acm_certificate.apps.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_route53_record" "non-prod_cert_validation" {
  name = "${aws_acm_certificate.non-prod.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.non-prod.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.non-prod.id}"
  records = ["${aws_acm_certificate.non-prod.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

resource "aws_acm_certificate_validation" "apps" {
  certificate_arn = "${aws_acm_certificate.apps.arn}"
  validation_record_fqdns = ["${aws_route53_record.apps_cert_validation.fqdn}"]
}

resource "aws_acm_certificate_validation" "non-prod" {
  certificate_arn = "${aws_acm_certificate.non-prod.arn}"
  validation_record_fqdns = ["${aws_route53_record.non-prod_cert_validation.fqdn}"]
}

output "apps_acm_arn" {
  value = "${aws_acm_certificate.apps.arn}"
}
