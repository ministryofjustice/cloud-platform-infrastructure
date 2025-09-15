# #################
# # Route53 / DNS #
# #################

resource "aws_route53_zone" "cluster" {
  name          = "${terraform.workspace}.cloud-platform.service.justice.gov.uk."
  force_destroy = true
}

resource "aws_route53_record" "parent_zone_cluster_ns" {
  zone_id = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = aws_route53_zone.cluster.name
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.cluster.name_servers[0],
    aws_route53_zone.cluster.name_servers[1],
    aws_route53_zone.cluster.name_servers[2],
    aws_route53_zone.cluster.name_servers[3],
  ]
}

resource "aws_route53_zone" "internal_ingress_controller_zone" {
  count         = local.is_live_cluster ? 1 : 0
  name          = "internal.cloud-platform.service.justice.gov.uk."
  force_destroy = true
}

resource "aws_route53_record" "parent_zone_internal_ns" {
  count   = local.is_live_cluster ? 1 : 0
  zone_id = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = aws_route53_zone.internal_ingress_controller_zone[count.index].name
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.internal_ingress_controller_zone[count.index].name_servers[0],
    aws_route53_zone.internal_ingress_controller_zone[count.index].name_servers[1],
    aws_route53_zone.internal_ingress_controller_zone[count.index].name_servers[2],
    aws_route53_zone.internal_ingress_controller_zone[count.index].name_servers[3],
  ]
}

resource "aws_route53_zone" "external-dns-route53-test-zone" {
  count = local.is_live_cluster ? 1 : 0
  name  = "ext-dns-test.cloud-platform.service.justice.gov.uk."
}

resource "aws_route53_record" "external-dns-parent-zone-ns" {
  count   = local.is_live_cluster ? 1 : 0
  zone_id = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = aws_route53_zone.external-dns-route53-test-zone[count.index].name
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.external-dns-route53-test-zone[count.index].name_servers[0],
    aws_route53_zone.external-dns-route53-test-zone[count.index].name_servers[1],
    aws_route53_zone.external-dns-route53-test-zone[count.index].name_servers[2],
    aws_route53_zone.external-dns-route53-test-zone[count.index].name_servers[3],
  ]
}

resource "aws_route53_zone" "external-dns-route53-test-zone-2" {
  count = local.is_live_cluster ? 1 : 0
  name  = "ext-dns-test-2.cloud-platform.service.justice.gov.uk."
}

resource "aws_route53_record" "external-dns-2-parent-zone-ns" {
  count   = local.is_live_cluster ? 1 : 0
  zone_id = data.aws_route53_zone.cloud_platform_justice_gov_uk.zone_id
  name    = aws_route53_zone.external-dns-route53-test-zone-2[count.index].name
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.external-dns-route53-test-zone-2[count.index].name_servers[0],
    aws_route53_zone.external-dns-route53-test-zone-2[count.index].name_servers[1],
    aws_route53_zone.external-dns-route53-test-zone-2[count.index].name_servers[2],
    aws_route53_zone.external-dns-route53-test-zone-2[count.index].name_servers[3],
  ]
}
