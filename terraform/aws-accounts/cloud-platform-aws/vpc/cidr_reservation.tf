# This is a temporary measure to stop resources from allocating IPs to this range
# as there is an overlap in the transit gateway elsewhere.
# Slack link: https://mojdt.slack.com/archives/C514ETYJX/p1782469276555129

resource "aws_ec2_subnet_cidr_reservation" "private_euw2_az1" {
  count = terraform.workspace == "live-1" ? 1 : 0

  cidr_block       = "172.20.32.0/24"
  reservation_type = "prefix"
  subnet_id        = module.vpc.private_subnets[0]

  description = "CIDR reservation for private subnet in eu-west-2a"
}
