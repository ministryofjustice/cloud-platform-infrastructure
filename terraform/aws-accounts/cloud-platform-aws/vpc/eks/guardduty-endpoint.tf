resource "aws_security_group" "guardduty_vpce" {
  name        = "guardduty-vpce-sg"
  description = "Security group for GuardDuty VPC endpoint"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.20.0.0/16"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "guardduty-vpce-sg"
  }
}

# GuardDuty interface endpoint
resource "aws_vpc_endpoint" "guardduty_runtime" {
  vpc_id            = data.aws_vpc.selected.id
  vpc_endpoint_type = "Interface"

  service_name = "com.amazonaws.eu-west-2.guardduty-data"

  subnet_ids         = data.aws_subnets.eks_private.ids
  security_group_ids = [aws_security_group.guardduty_vpce.id]

  private_dns_enabled = true

  tags = {
    Name = "guardduty-runtime-endpoint"
  }
}