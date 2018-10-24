output "ssh-public" {
  value = "${tls_private_key.haproxy_private_key.public_key_pem}"
}

output "ssh-private" {
  value = "${tls_private_key.haproxy_private_key.private_key_pem}"
}

output "haproxy-nodes-ips" {
  value = "${aws_instance.haproxy_node.*.public_ip}"
}

output "elb-dns" {
  value = "${aws_elb.haproxy_elb.dns_name}"
}

output "haproxy-dns" {
  value = "${aws_route53_record.www.name}"
}
