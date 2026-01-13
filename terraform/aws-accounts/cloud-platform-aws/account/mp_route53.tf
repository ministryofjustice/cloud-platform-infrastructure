## Temporary CP30 Route53 NS record for temp.cloud-platform.service.justice.gov.uk

resource "aws_route53_record" "temp_cloud_platform" {
  zone_id = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = "temp.cloud-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = 300
  records = [
    "ns-439.awsdns-54.com.",
    "ns-1019.awsdns-63.net.",
    "ns-1033.awsdns-01.org.",
    "ns-1938.awsdns-50.co.uk.",
  ]
}