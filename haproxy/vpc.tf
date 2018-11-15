data "aws_availability_zones" "all" {}

resource "aws_vpc" "default" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_hostnames = true

  tags {
    Name = "haproxy_vpc_${random_id.id.hex}"
  }
}

resource "aws_subnet" "haproxy_subnet" {
  vpc_id                  = "${aws_vpc.default.id}"
  count                   = "${var.aws_az_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)}"
  availability_zone       = "${data.aws_availability_zones.all.names[count.index]}"
  map_public_ip_on_launch = true

  tags {
    Name = "haproxy_subnet_${random_id.id.hex}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "haproxy_ig_${random_id.id.hex}"
  }
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "aws_route_table_${random_id.id.hex}"
  }
}

resource "aws_route_table_association" "a" {
  count          = "${var.aws_az_count}"
  subnet_id      = "${element(aws_subnet.haproxy_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.r.id}"
}
