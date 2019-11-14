output "cluster_dns_zone_name" {
  value = aws_route53_zone.cluster.name
}

output "cluster_dns_zone_id" {
  value = aws_route53_zone.cluster.zone_id
}

