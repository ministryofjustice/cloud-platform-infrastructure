resource "aws_route53_zone" "haproxy" {
  name = "${var.haproxy_domain}"
}

resource "aws_route53_record" "parent" {
  zone_id = "${var.parent_zone}"
  type    = "NS"
  name    = "${var.haproxy_domain}"
  records = ["${aws_route53_zone.haproxy.name_servers}"]
  ttl     = "300"
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.haproxy.zone_id}"
  name    = "${var.haproxy_host}.${var.haproxy_domain}"
  type    = "CNAME"
  records = ["${aws_lb.haproxy_alb.dns_name}"]
  ttl     = "300"
}
