###############
# EKS Cluster #
###############

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

locals {
  # desired_capcity change is a manual step after initial cluster creation (when no cluster-autoscaler)
  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/835
  node_groups_count = {
    live    = "54"
    manager = "4"
    default = "3"
  }

  node_size = {
    live    = ["r5.xlarge", "r4.xlarge"]
    manager = ["m5.xlarge", "m4.xlarge"]
    default = ["m5.large", "m4.large"]
  }

  monitoring_node_size = {
    live    = ["r4.2xlarge", "r5.2xlarge"]
    manager = ["t3.medium", "t2.medium"]
    default = ["t3.medium", "t2.medium"]
  }

  default_ng = {
    desired_capacity     = lookup(local.node_groups_count, terraform.workspace, local.node_groups_count["default"])
    max_capacity         = 60
    min_capacity         = 1
    subnets              = data.aws_subnet_ids.private.ids
    bootstrap_extra_args = "--use-max-pods false"
    kubelet_extra_args   = "--max-pods=110"

    create_launch_template = true
    pre_userdata = templatefile("${path.module}/templates/user-data.tpl", {
      dockerhub_credentials = base64encode("${var.dockerhub_user}:${var.dockerhub_token}")
    })

    instance_types = lookup(local.node_size, terraform.workspace, local.node_size["default"])
    k8s_labels = {
      Terraform = "true"
      Cluster   = terraform.workspace
      Domain    = local.fqdn
    }
    additional_tags = {
      default_ng    = "true"
      application   = "moj-cloud-platform"
      business-unit = "platforms"
    }
  }

  monitoring_ng = {
    desired_capacity = 2
    max_capacity     = 3
    min_capacity     = 1
    subnets          = data.aws_subnet_ids.private_zone_2b.ids

    create_launch_template = true
    pre_userdata = templatefile("${path.module}/templates/user-data.tpl", {
      dockerhub_credentials = base64encode("${var.dockerhub_user}:${var.dockerhub_token}")
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

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v17.3.0"

  cluster_name                  = terraform.workspace
  subnets                       = concat(tolist(data.aws_subnet_ids.private.ids), tolist(data.aws_subnet_ids.public.ids))
  vpc_id                        = data.aws_vpc.selected.id
  write_kubeconfig              = false
  cluster_version               = "1.19"
  enable_irsa                   = true
  cluster_enabled_log_types     = var.cluster_enabled_log_types
  cluster_log_retention_in_days = var.cluster_log_retention_in_days
  wait_for_cluster_timeout      = "900"
  node_groups = {
    default_ng    = local.default_ng
    monitoring_ng = local.monitoring_ng
  }

  # add System Manager permissions to the worker nodes. This will enable access to worker nodes using session manager
  workers_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  # Out of the box you can't specify groups to map, just users. Some people did some workarounds
  # we can explore later: https://ygrene.tech/mapping-iam-groups-to-eks-user-access-66fd745a6b77
  map_users = [
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
      userarn  = "arn:aws:iam::754256621582:user/RazvanCosma"
      username = "RazvanCosma"
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

  tags = {
    Terraform = "true"
    Cluster   = terraform.workspace
    Domain    = local.fqdn
  }
}
