resource "aws_route53_zone" "haproxy" {
  name         = "haproxy-test.cloud-platform.dsd.io"
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.haproxy.zone_id}"
  name    = "www.${aws_route53_zone.haproxy.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_elb.hapee_elb.dns_name}"]
}
