// file: modules/vpc/main.tf

// ---------------------------------------------------------------------------------------------------------------------
// VPC
// ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "${var.name}"
  }
}

// ---------------------------------------------------------------------------------------------------------------------
// Gateways
// ---------------------------------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name}"
  }
}

// ---------------------------------------------------------------------------------------------------------------------
// Subnets
// ---------------------------------------------------------------------------------------------------------------------

resource "aws_subnet" "internal" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${element(var.internal_subnets, count.index)}"
  availability_zone = "${element(sort(var.availability_zones), count.index)}"
  count             = "${length(var.internal_subnets) >= length(var.availability_zones) ? length(var.availability_zones) : 0}"

  tags {
    Name = "${var.name}-${format("internal-%03d", count.index + 1)}"
  }
}

resource "aws_subnet" "external" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.external_subnets, count.index)}"
  availability_zone       = "${element(sort(var.availability_zones), count.index)}"
  count                   = "${length(var.external_subnets) >= length(var.availability_zones) ? length(var.availability_zones) : 0}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.name}-${format("external-%03d", count.index + 1)}"
  }
}

// ---------------------------------------------------------------------------------------------------------------------
// Route Tables
// ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table" "external" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name}-external-001"
  }
}

resource "aws_route" "external" {
  route_table_id         = "${aws_route_table.external.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

resource "aws_route_table" "internal" {
  count  = "${length(var.availability_zones)}"
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name}-${format("internal-%03d", count.index + 1)}"
  }
}

// ---------------------------------------------------------------------------------------------------------------------
// Security Group
// ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "main" {
  vpc_id      = "${aws_vpc.main.id}"
  name_prefix = "main-"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// ---------------------------------------------------------------------------------------------------------------------
// Route associations
// ---------------------------------------------------------------------------------------------------------------------

resource "aws_route_table_association" "internal" {
  count          = "${length(var.internal_subnets) >= length(var.availability_zones) ? length(var.availability_zones) : 0}"
  subnet_id      = "${element(aws_subnet.internal.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.internal.*.id, count.index)}"
}

resource "aws_route_table_association" "external" {
  count          = "${length(var.external_subnets) >= length(var.availability_zones) ? length(var.availability_zones) : 0}"
  subnet_id      = "${element(aws_subnet.external.*.id, count.index)}"
  route_table_id = "${aws_route_table.external.id}"
}