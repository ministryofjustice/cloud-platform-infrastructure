## Temporary CP30 Route53 NS record for temp.cloud-platform.service.justice.gov.uk

resource "aws_route53_record" "temp_cloud_platform" {
  zone_id = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = "temp.cloud-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = 300
  records = [
    "ns-1471.awsdns-55.org.",
    "ns-605.awsdns-11.net.",
    "ns-1805.awsdns-33.co.uk.",
    "ns-282.awsdns-35.com.",
  ]
}