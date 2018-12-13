resource "aws_route53_record" "www" {
  count   = "${var.manage_alias ? 1 : 0}"
  zone_id = "${var.parent_zone}"
  name    = "${var.haproxy_domain}"
  type    = "A"

  alias {
    name                   = "${aws_lb.haproxy_alb.dns_name}"
    zone_id                = "${aws_lb.haproxy_alb.zone_id}"
    evaluate_target_health = false
  }
}
