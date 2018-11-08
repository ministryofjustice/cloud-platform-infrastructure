resource "aws_route53_record" "www" {
  zone_id = "${var.parent_zone}"
  name    = "${var.haproxy_domain}"
  type    = "CNAME"
  records = ["${aws_lb.haproxy_alb.dns_name}"]
  ttl     = "300"
}
