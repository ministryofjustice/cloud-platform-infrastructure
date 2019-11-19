###############
# EKS Cluster #
###############

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v7.0.0"

  cluster_name       = local.cluster_name
  subnets            = concat(module.cluster_vpc.private_subnets, module.cluster_vpc.public_subnets)
  vpc_id             = module.cluster_vpc.vpc_id
  config_output_path = "./files/"

  worker_groups = [
    {
      instance_type        = var.worker_node_machine_type
      subnets              = module.cluster_vpc.private_subnets
      asg_max_size         = 30
      asg_min_size         = 0
      asg_desired_capacity = var.cluster_node_count
      key_name             = local.cluster_base_domain_name
    }
  ]

  map_users = [
    {
      userarn  = "arn:aws:iam::754256621582:user/AlejandroGarrido"
      username = "AlejandroGarrido"
      groups   = ["system:masters"]
    },
  ]

  tags = {
    Terraform = "true"
    Cluster   = local.cluster_name
    Domain    = local.cluster_base_domain_name
  }

}
