resource "aws_security_group" "interface_endpoints" {
  name        = "vpc-interface-endpoints-sg"
  description = "Allow HTTPS from VPC to Interface Endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTPS from vpc"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow return HTTPS"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-interface-endpoints-sg"
  }
}
