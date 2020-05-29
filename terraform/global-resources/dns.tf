# Reference to existing base DNS zone
data "aws_route53_zone" "justice_gov_uk" {
  provider = aws.dsd
  name     = "service.justice.gov.uk."
}

# new parent DNS zone for clusters
resource "aws_route53_zone" "cloud-platform_justice_gov_uk" {
  provider = aws.cloud-platform
  name     = "cloud-platform.service.justice.gov.uk."
}

resource "aws_route53_record" "cloud-platform_justice_gov_uk_NS" {
  provider = aws.dsd
  zone_id  = data.aws_route53_zone.justice_gov_uk.zone_id
  name     = aws_route53_zone.cloud-platform_justice_gov_uk.name
  type     = "NS"
  ttl      = "300"

  records = aws_route53_zone.cloud-platform_justice_gov_uk.name_servers
}

