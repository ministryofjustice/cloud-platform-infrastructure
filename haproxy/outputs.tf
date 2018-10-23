output "ELB DNS address" {
  value = "${aws_elb.hapee_elb.dns_name}"
}