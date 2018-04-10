output "k8s_zone_id" {
  value = "${aws_route53_zone.k8s.zone_id}"
}

output "k8s_domain_name" {
  value = "${var.k8s_domain_prefix}.${var.base_domain_name}"
}
