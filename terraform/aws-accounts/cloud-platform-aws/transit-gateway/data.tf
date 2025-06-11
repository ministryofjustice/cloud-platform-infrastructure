data "aws_vpc" "inspection_vpc" {
  filter {
    name   = "tag:Name"
    values = ["inspection-vpc"]
  }
}

data "aws_subnets" "inspection_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.inspection_vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["transit-*"]
  }
}

data "aws_subnet" "inspection_vpc_intra" {
  for_each = toset(data.aws_subnets.inspection_vpc.ids)
  id       = each.key
}
