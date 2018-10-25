resource "aws_route53_zone" "haproxy" {
  name = "${var.haproxy_domain}"
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.haproxy.zone_id}"
  name    = "${var.haproxy_host}.${var.haproxy_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_elb.haproxy_elb.dns_name}"]
}
