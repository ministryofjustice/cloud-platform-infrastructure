# Reference to existing base DNS zone
data "aws_route53_zone" "integration_dsd_io" {
  name = "integration.dsd.io."
}

# parent DNS zone for all clusters
resource "aws_route53_zone" "k8s_integration_dsd_io" {
  name = "k8s.integration.dsd.io."
}

resource "aws_route53_record" "k8s_integration_dsd_io_NS" {
  zone_id = "${data.aws_route53_zone.integration_dsd_io.zone_id}"
  name    = "${aws_route53_zone.k8s_integration_dsd_io.name}"
  type    = "NS"
  ttl     = "300"

  records = [
    "${aws_route53_zone.k8s_integration_dsd_io.name_servers}",
  ]
}

data "aws_route53_zone" "justice_gov_uk" {
  provider = "aws.dsd"
  name     = "justice.gov.uk."
}

# new parent DNS zone for clusters
resource "aws_route53_zone" "cloud-platform_justice_gov_uk" {
  provider = "aws.cloud-platform"
  name     = "cloud-platform.justice.gov.uk."
}

resource "aws_route53_record" "cloud-platform_justice_gov_uk_NS" {
  provider = "aws.dsd"
  zone_id  = "${data.aws_route53_zone.justice_gov_uk.zone_id}"
  name     = "${aws_route53_zone.cloud-platform_justice_gov_uk.name}"
  type     = "NS"
  ttl      = "300"

  records = [
    "${aws_route53_zone.cloud-platform_justice_gov_uk.name_servers}",
  ]
}
