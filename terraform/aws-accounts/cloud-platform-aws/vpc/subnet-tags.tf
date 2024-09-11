data "aws_subnet" "eks_private_1" {
  cidr_block = cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, 4)
  vpc_id = module.vpc.vpc_id
  depends_on = [module.vpc]
}

resource "aws_ec2_tag" "eks_private_1" {
  resource_id = data.aws_subnet.eks_private_1.id
  key         = "SubnetType"
  value       = "EKS-Private"
}

data "aws_subnet" "eks_private_2" {
  cidr_block = cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, 5)
  vpc_id = module.vpc.vpc_id
  depends_on = [module.vpc]
}

resource "aws_ec2_tag" "eks_private_2" {
  resource_id = data.aws_subnet.eks_private_2.id
  key         = "SubnetType"
  value       = "EKS-Private"
} 

data "aws_subnet" "eks_private_3" {
  cidr_block = cidrsubnet(lookup(local.vpc_cidr, terraform.workspace, local.vpc_cidr["default"]), 3, 6)
  vpc_id = module.vpc.vpc_id
  depends_on = [module.vpc]
}

resource "aws_ec2_tag" "eks_private_3" {
  resource_id = data.aws_subnet.eks_private_3.id
  key         = "SubnetType"
  value       = "EKS-Private"
} 