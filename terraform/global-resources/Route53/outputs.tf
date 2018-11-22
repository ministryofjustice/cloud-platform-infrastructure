output "name_servers" {
  value = "${aws_route53_zone.hosted_zones.*.name_servers}"
}

output "zone_id" {
  value = "${aws_route53_zone.hosted_zones.*.zone_id}"
}
