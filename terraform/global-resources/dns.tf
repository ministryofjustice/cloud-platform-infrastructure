# Reference to existing base DNS zone
data "aws_route53_zone" "base" {
  name = "${var.base_domain_name}."
}

# parent DNS zone for all clusters
resource "aws_route53_zone" "k8s" {
  name = "${var.k8s_domain_prefix}.${var.base_domain_name}."
}

resource "aws_route53_record" "k8s_ns" {
  zone_id = "${data.aws_route53_zone.base.zone_id}"
  name    = "${var.k8s_domain_prefix}.${var.base_domain_name}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.k8s.name_servers}",
  ]
}
