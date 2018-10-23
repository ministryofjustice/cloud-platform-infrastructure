output "ELB DNS address" {
  value = "${aws_elb.hapee_elb.dns_name}"
}

output "Public Key Pem" {
  value = "${tls_private_key.hapee_private_key.public_key_pem}"
}

output "Private Key Pem" {
  value = "${tls_private_key.hapee_private_key.private_key_pem}"
}

output "Key Pair Fingerprint" {
  value = "${aws_key_pair.hapee_key_pair.fingerprint}"
}

output "HAPEE node public IPs" {
  value = "${aws_instance.hapee_node.*.public_ip}"
}
