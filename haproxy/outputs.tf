output "ssh-private" {
  value = "${tls_private_key.haproxy_private_key.private_key_pem}"
}

output "alb-dns" {
  value = "${aws_lb.haproxy_alb.dns_name}"
}

output "haproxy-dns" {
  value = "${aws_route53_record.www.name}"
}

output "public-ips" {
  value = ["${aws_instance.haproxy_node.*.public_ip}"]
}
