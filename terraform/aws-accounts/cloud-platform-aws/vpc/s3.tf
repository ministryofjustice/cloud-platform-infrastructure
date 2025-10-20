module "aws_s3_vpce" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.0.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service             = "s3"
      service_type        = "Gateway"
      route_table_ids     = module.vpc.private_route_table_ids
      tags                = { Name = "${terraform.workspace}-s3-vpce" }
    }
  }

  depends_on = [
    module.vpc
  ]
}
