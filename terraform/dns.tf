# Reference to existing integration DNS zone
data "aws_route53_zone" "integration" {
  name = "${var.base_domain_name}."
}


# parent DNS zone for all clusters
resource "aws_route53_zone" "k8s" {
  name = "${local.k8s_domain_name}."
}

resource "aws_route53_record" "k8s_ns" {
  zone_id = "${data.aws_route53_zone.integration.zone_id}"
  name    = "${local.k8s_domain_name}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.k8s.name_servers}"
  ]
}


# DNS zone for sandbox cluster
resource "aws_route53_zone" "sandbox" {
  name = "${local.sandbox_domain_name}."
}

resource "aws_route53_record" "sandbox_ns" {
  zone_id = "${aws_route53_zone.k8s.zone_id}"
  name    = "${local.sandbox_domain_name}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.sandbox.name_servers}"
  ]
}
