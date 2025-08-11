locals {
  route53_zones = toset(["aws.prd.legalservices.gov.uk"])
  route53_records = {
    "aws.prd.legalservices.gov.uk" = [
      { name  = "cwa-prod-db", type = "A",
        alias = { name = "cwa-production-database-nlb-12d44851fda0f196.elb.eu-west-2.amazonaws.com", zone_id = "ZD4D7Y8KGAS4G" }
      }
    ]
  }
}

resource "aws_route53_zone" "this" {
  for_each = local.route53_zones
  name     = each.key
  dynamic "vpc" {
    for_each = { for k in keys(module.vpc) : k => module.vpc[k].vpc_id }
    content {
      vpc_id = vpc.value
    }
  }
}

module "route53-records" {
  depends_on = [aws_route53_zone.this]
  source     = "terraform-aws-modules/route53/aws//modules/records"
  version    = "5.0.0"
  for_each   = local.route53_zones
  records    = local.route53_records[each.key]
  zone_id    = aws_route53_zone.this[each.key].zone_id
}