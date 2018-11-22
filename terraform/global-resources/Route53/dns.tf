resource "aws_route53_zone" "hosted_zones" {
  count = "${length(split(",", var.route53_domain))}"
  name  = "${element(split(",", var.route53_domain), count.index)}"
}
