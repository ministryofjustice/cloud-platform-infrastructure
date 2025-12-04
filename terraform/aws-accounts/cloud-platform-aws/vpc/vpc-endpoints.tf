# Security group for GuardDuty interface-type VPC endpoints

resource "aws_security_group" "guardduty_vpce" {
  name        = "${terraform.workspace}-guardduty-vpce-sg"
  description = "Security group for GuardDuty VPC endpoint"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-guardduty-vpce-sg"
  }

  depends_on = [
    module.vpc
  ]
}

# Consolidated VPC Endpoints

module "aws_vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.0.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {

    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "${terraform.workspace}-s3-vpce" }
    }

    # GuardDuty Interface endpoint — private connection for GuardDuty data
    guardduty = {
      service             = "guardduty-data"
      private_dns_enabled = true
      security_group_ids  = [aws_security_group.guardduty_vpce.id]
      subnet_ids          = aws_subnet.eks_private[*].id
      tags                = { Name = "${terraform.workspace}-guardduty-monitoring-vpce" }
    }
  }

  depends_on = [
    module.vpc
  ]
}