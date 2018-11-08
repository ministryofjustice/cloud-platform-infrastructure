resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.haproxy_domain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  name    = "${lookup(aws_acm_certificate.cert.domain_validation_options[0], "resource_record_name")}"
  type    = "${lookup(aws_acm_certificate.cert.domain_validation_options[0], "resource_record_type")}"
  zone_id = "${var.parent_zone}"
  records = ["${lookup(aws_acm_certificate.cert.domain_validation_options[0], "resource_record_value")}"]
  ttl     = 60
}
