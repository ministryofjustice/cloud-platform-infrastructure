###############
# EKS Cluster #
###############

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
    command     = "aws"
  }
}

locals {
  cluster_name = terraform.workspace
  # desired_capcity change is a manual step after initial cluster creation (when no cluster-autoscaler)
  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/835
  node_groups_count = {
    live    = "54"
    live-2  = "7"
    manager = "4"
    default = "3"
  }
  # Default node group minimum capacity 
  default_ng_min_count = {
    live    = "42"
    live-2  = "7"
    manager = "4"
    default = "2"
  }
  # To manage different cluster versions
  cluster_version = {
    live    = "1.22"
    live-2  = "1.22"
    manager = "1.22"
    default = "1.22"
  }
  node_size = {
    live    = ["r5.xlarge", "r5.2xlarge", "r5a.xlarge"]
    live-2  = ["r5.xlarge", "r5.2xlarge", "r5a.xlarge"]
    manager = ["m5.xlarge", "m5.2xlarge", "m5a.xlarge"]
    default = ["m5.large", "m5.xlarge", "m5a.large"]
  }

  monitoring_node_size = {
    live    = ["r4.2xlarge", "r5.2xlarge"]
    live-2  = ["r4.2xlarge", "r5.2xlarge"]
    manager = ["t3.medium", "t2.medium"]
    default = ["t3.medium", "t2.medium"]
  }

  dockerhub_credentials = base64encode("${var.cp_dockerhub_user}:${var.cp_dockerhub_token}")
  default_ng_12_22 = {
    desired_size         = lookup(local.node_groups_count, terraform.workspace, local.node_groups_count["default"])
    max_size             = 85
    min_size             = lookup(local.default_ng_min_count, terraform.workspace, local.default_ng_min_count["default"])
    subnet_ids           = data.aws_subnets.private.ids
    bootstrap_extra_args = "--use-max-pods false"
    kubelet_extra_args   = "--max-pods=110"

    create_launch_template = true
    pre_bootstrap_user_data = templatefile("${path.module}/templates/user-data.tpl", {
      dockerhub_credentials = local.dockerhub_credentials
    })

    instance_types = lookup(local.node_size, terraform.workspace, local.node_size["default"])
    labels = {
      Terraform = "true"
      Cluster   = terraform.workspace
      Domain    = local.fqdn
    }
    tags = {
      default_ng    = "true"
      application   = "moj-cloud-platform"
      business-unit = "platforms"
    }
  }

  monitoring_ng = {
    desired_size = 2
    max_size     = 3
    min_size     = 2
    subnet_ids   = data.aws_subnets.private_zone_2b.ids

    create_launch_template = true
    pre_bootstrap_user_data = templatefile("${path.module}/templates/user-data.tpl", {
      dockerhub_credentials = local.dockerhub_credentials
    })

    instance_types = lookup(local.monitoring_node_size, terraform.workspace, local.monitoring_node_size["default"])
    k8s_labels = {
      Terraform                                     = "true"
      "cloud-platform.justice.gov.uk/monitoring-ng" = "true"
      Cluster                                       = terraform.workspace
      Domain                                        = local.fqdn
    }
    additional_tags = {
      monitoring_ng = "true"
      application   = "moj-cloud-platform"
      business-unit = "platforms"
    }
    taints = [
      {
        key    = "monitoring-node"
        value  = true
        effect = "NO_SCHEDULE"
      }
    ]
  }

  tags = {
    Terraform = "true"
    Cluster   = terraform.workspace
    Domain    = local.fqdn
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.2"

  cluster_name                           = terraform.workspace
  subnet_ids                             = concat(tolist(data.aws_subnets.private.ids), tolist(data.aws_subnets.public.ids))
  vpc_id                                 = data.aws_vpc.selected.id
  cluster_version                        = lookup(local.cluster_version, terraform.workspace, local.cluster_version["default"])
  enable_irsa                            = true
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days
  cluster_security_group_description     = "EKS cluster security group."
<<<<<<< HEAD
  cluster_security_group_name            = "cp-1512-1632-eks_cluster_sg"
  iam_role_name                          = "cp-1512-163220221215163521347300000001"
  prefix_separator                       = ""
=======
  cluster_security_group_name            = terraform.workspace
  iam_role_name                          = terraform.workspace
  prefix_separator                       = ""

  node_security_group_tags = {
    "kubernetes.io/cluster/${terraform.workspace}" = null
  }

>>>>>>> c19a7e82 (Update with latest changes)

  eks_managed_node_groups = {
    default_ng_12_22 = local.default_ng_12_22
    monitoring_ng    = local.monitoring_ng
  }

  # add System Manager permissions to the worker nodes. This will enable access to worker nodes using session manager
  iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  create_aws_auth_configmap = true

  # Out of the box you can't specify groups to map, just users. Some people did some workarounds
  # we can explore later: https://ygrene.tech/mapping-iam-groups-to-eks-user-access-66fd745a6b77
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::754256621582:user/PoornimaKrishnasamy"
      username = "PoornimaKrishnasamy"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/paulWyborn"
      username = "paulWyborn"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/SabluMiah"
      username = "SabluMiah"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/jasonBirchall"
      username = "jasonBirchall"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/SteveMarshall"
      username = "SteveMarshall"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/VijayVeeranki"
      username = "VijayVeeranki"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/JackStockley"
      username = "JackStockley"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/JakeMulley"
      username = "JakeMulley"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/SteveWilliams"
      username = "SteveWilliams"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/JaskaranSarkaria"
      username = "JaskaranSarkaria"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/cloud-platform/manager-concourse"
      username = "manager-concourse"
      groups   = ["system:masters"]
    },
    # Manager-concourse-cloud-platform-admin used by the cloud-platform-cli
    {
      userarn  = "arn:aws:iam::754256621582:user/cloud-platform/manager-concourse-cloud-platform-admin"
      username = "manager-concourse-cloud-platform-admin"
      groups   = ["system:masters"]
    }
  ]

  tags = local.tags
}

#######################
# EKS Cluster add-ons #
#######################
module "aws_eks_addons" {
  source                  = "github.com/ministryofjustice/cloud-platform-terraform-eks-add-ons?ref=1.3.0"
  depends_on              = [module.eks.cluster]
  cluster_name            = terraform.workspace
  eks_cluster_id          = module.eks.cluster_id
  cluster_oidc_issuer_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  addon_tags              = local.tags
}
