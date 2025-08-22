locals {
  vpcs_to_attach = toset(["inspection-vpc", "live-1", "live-2"])
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
    values = ["*-transit-*"]
  }
}

# Gather subnets where naming convention hasn't been updated
data "aws_subnets" "legacy_transit" {
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

data "aws_subnet" "live_1" {
  for_each = toset(data.aws_subnets.transit["live-1"].ids)
  id       = each.key
}

data "aws_subnet" "live_2" {
  for_each = toset(data.aws_subnets.transit["live-2"].ids)
  id       = each.key
}

data "aws_subnet" "inspection_vpc" {
  for_each = toset(data.aws_subnets.legacy_transit["inspection-vpc"].ids)
  id       = each.key
}
