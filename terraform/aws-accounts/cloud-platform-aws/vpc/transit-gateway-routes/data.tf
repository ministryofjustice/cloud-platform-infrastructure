data "aws_ec2_transit_gateway" "cloud-platform-transit-gateway" {
  filter {
    name   = "tag:Name"
    values = ["cloud-platform-transit-gateway"]
  }
}