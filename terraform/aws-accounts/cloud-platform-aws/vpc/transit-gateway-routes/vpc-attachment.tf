locals {
  vpcs_to_attach = toset(["live-1", "live-2"])
}

data "aws_ec2_transit_gateway" "pttp-tgw" {
  id = "tgw-026162f1ba39ce704"
}

data "aws_vpc" "selected" {
  for_each = local.vpcs_to_attach
  filter {
    name   = "tag:Name"
    values = [each.key]
  }
}

data "aws_subnets" "transit" {
  for_each = local.vpcs_to_attach
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected[each.key].id]
  }
  filter {
    name   = "tag:Name"
    values = ["transit-*"]
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "cp-live-pttp" {
  transit_gateway_id = data.aws_ec2_transit_gateway.pttp-tgw.id # eu-west-2 TGW
  subnet_ids         = toset(data.aws_subnets.transit["live-1"].ids)
  vpc_id             = data.aws_vpc.selected["live-1"].id

  tags = {
    Name  = "cp-live-pttp"
    Owner = "pttp-mojo-transit-gateway"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "cp-live-2-pttp" {
  transit_gateway_id = data.aws_ec2_transit_gateway.pttp-tgw.id # eu-west-2 TGW
  subnet_ids         = toset(data.aws_subnets.transit["live-2"].ids)
  vpc_id             = data.aws_vpc.selected["live-2"].id

  tags = {
    Name  = "cp-live-2-pttp"
    Owner = "pttp-mojo-transit-gateway"
  }
}