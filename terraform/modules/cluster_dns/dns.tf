resource "aws_route53_zone" "cluster" {
  name          = "${var.cluster_base_domain_name}."
  force_destroy = true
}

resource "aws_route53_record" "parent_zone_cluster_ns" {
  zone_id = var.parent_zone_id
  name    = aws_route53_zone.cluster.name
  type    = "NS"
  ttl     = "30"

  records = aws_route53_zone.cluster.name_servers
}

