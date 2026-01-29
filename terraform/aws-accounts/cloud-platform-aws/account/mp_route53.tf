## Temporary CP30 Route53 NS record for temp.cloud-platform.service.justice.gov.uk

resource "aws_route53_record" "development-temp_cloud_platform" {
  zone_id = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = "development-temp.cloud-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = 300
  records = [
    "ns-625.awsdns-14.net.",
    "ns-153.awsdns-19.com.",
    "ns-1651.awsdns-14.co.uk.",
    "ns-1428.awsdns-50.org.",
  ]
}

resource "aws_route53_record" "preproduction-temp_cloud_platform" {
  zone_id = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = "preproduction-temp.cloud-platform.service.justice.gov.uk "
  type    = "NS"
  ttl     = 300
  records = [
    "ns-798.awsdns-35.net.",
    "ns-388.awsdns-48.com.",
    "ns-1738.awsdns-25.co.uk.",
    "ns-1107.awsdns-10.org.",
  ]
}

resource "aws_route53_record" "nonlive-temp_cloud_platform" {
  zone_id = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = "nonlive-temp.cloud-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = 300
  records = [
    "ns-604.awsdns-11.net.",
    "ns-162.awsdns-20.com.",
    "ns-1875.awsdns-42.co.uk.",
    "ns-1154.awsdns-16.org.",
  ]
}

resource "aws_route53_record" "live-temp_cloud_platform" {
  zone_id = aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = "live-temp.cloud-platform.service.justice.gov.uk"
  type    = "NS"
  ttl     = 300
  records = [
    "ns-716.awsdns-25.net.",
    "ns-267.awsdns-33.com.",
    "ns-1233.awsdns-26.org.",
    "ns-1661.awsdns-15.co.uk.",
  ]
}