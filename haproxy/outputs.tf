output "ssh-private" {
  value = "${tls_private_key.haproxy_private_key.private_key_pem}"
}

output "alb-dns" {
  value = "${aws_lb.haproxy_alb.dns_name}"
}

output "haproxy-dns" {
  value = "${var.haproxy_domain}"
}

output "public-ips" {
  value = ["${aws_instance.haproxy_node.*.public_ip}"]
}
