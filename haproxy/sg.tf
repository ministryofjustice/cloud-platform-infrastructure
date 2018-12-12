resource "aws_security_group" "instance_sg1" {
  name        = "instance_sg1_${random_id.id.hex}"
  description = "pass tcp/22 by default"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags {
    Name   = "cp-haproxy-split"
    Domain = "${var.haproxy_domain}"
  }
}

resource "aws_security_group" "instance_sg2" {
  name        = "instance_sg2_${random_id.id.hex}"
  description = "pass ALB traffic  by default"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.alb.id}"]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.alb.id}"]
  }

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = ["${aws_security_group.instance_sg1.id}", "${aws_security_group.alb.id}"]
  }

  tags {
    Name   = "cp-haproxy-split"
    Domain = "${var.haproxy_domain}"
  }
}

resource "aws_security_group" "alb" {
  name        = "alb_sg_${random_id.id.hex}"
  description = "for haproxy"

  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = ["aws_internet_gateway.gw"]

  tags {
    Name   = "cp-haproxy-split"
    Domain = "${var.haproxy_domain}"
  }
}
