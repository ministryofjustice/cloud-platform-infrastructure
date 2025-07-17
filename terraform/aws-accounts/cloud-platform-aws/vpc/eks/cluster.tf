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
  # desired_capacity change is a manual step after initial cluster creation (when no cluster-autoscaler)
  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/835
  node_groups_count = {
    live    = "65"
    live-2  = "7"
    manager = "4"
    default = "3"
  }
  # Default node group minimum capacity
  default_ng_min_count = {
    live    = "65"
    live-2  = "2"
    manager = "4"
    default = "2"
  }

  # Monitoring node group desired capacity
  default_mon_desired_count = {
    live    = "4"
    live-2  = "3"
    manager = "4"
    default = "3"
  }
  # Monitoring node group minimum capacity
  default_mon_min_count = {
    live    = "4"
    live-2  = "3"
    manager = "4"
    default = "3"
  }
  # To manage different cluster versions
  cluster_version = {
    live    = "1.31"
    live-2  = "1.31"
    manager = "1.31"
    default = "1.31"
  }

  node_size = {
    live    = ["r6i.2xlarge", "r6i.xlarge", "r5.2xlarge"]
    live-2  = ["r6i.2xlarge", "r6i.xlarge", "r5.2xlarge"]
    manager = ["m6a.2xlarge", "m6a.4xlarge", "m6i.2xlarge"]
    default = ["m6a.xlarge", "m6a.2xlarge", "m6i.xlarge"]
  }

  monitoring_node_size = {
    live    = ["r7i.12xlarge", "r6i.12xlarge", "r7i.16xlarge", "r6i.16xlarge"]
    live-2  = ["r6i.2xlarge", "r5a.2xlarge"]
    manager = ["t3a.medium", "t3.medium"]
    default = ["t3a.medium", "t3.medium"]
  }

  thanos_node_size = {
    manager = ["m6a.2xlarge", "m6a.4xlarge", "m6i.2xlarge"]
    default = ["m6a.xlarge", "m6a.2xlarge", "m6i.xlarge"]
  }

  dockerhub_credentials = base64encode("${var.cp_dockerhub_user}:${var.cp_dockerhub_token}")

  tags = {
    Terraform = "true"
    Cluster   = terraform.workspace
    Domain    = local.fqdn
  }

  default_ng_16_09_24 = {
    desired_size = lookup(local.node_groups_count, terraform.workspace, local.node_groups_count["default"])
    max_size     = 85
    min_size     = lookup(local.default_ng_min_count, terraform.workspace, local.default_ng_min_count["default"])

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 200
          volume_type           = "gp3"
          iops                  = 0
          encrypted             = false
          kms_key_id            = ""
          delete_on_termination = true
        }
      }
    }

    subnet_ids           = data.aws_subnets.eks_private.ids
    bootstrap_extra_args = "--use-max-pods false"
    kubelet_extra_args   = "--max-pods=110"
    name                 = "${terraform.workspace}-def-ng"

    create_security_group  = false
    create_launch_template = true
    pre_bootstrap_user_data = templatefile("${path.module}/templates/user-data-140824.tpl", {
      dockerhub_credentials = local.dockerhub_credentials
    })
    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

    instance_types = lookup(local.node_size, terraform.workspace, local.node_size["default"])
    labels = {
      Terraform                                  = "true"
      "cloud-platform.justice.gov.uk/default-ng" = "true"
      Cluster                                    = terraform.workspace
      Domain                                     = local.fqdn
    }

    tags = {
      default_ng    = "true"
      application   = "moj-cloud-platform"
      business-unit = "platforms"
    }
  }

  monitoring_ng_19_03_25 = {
    desired_size = lookup(local.default_mon_desired_count, terraform.workspace, local.default_mon_desired_count["default"])
    max_size     = 6
    min_size     = lookup(local.default_mon_min_count, terraform.workspace, local.default_mon_min_count["default"])
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 140
          volume_type           = "gp3"
          iops                  = 0
          encrypted             = false
          kms_key_id            = ""
          delete_on_termination = true
        }
      }
    }


    subnet_ids = data.aws_subnets.eks_private.ids
    name       = "${terraform.workspace}-mon-ng"

    create_security_group  = false
    create_launch_template = true
    pre_bootstrap_user_data = templatefile("${path.module}/templates/user-data-140824.tpl", {
      dockerhub_credentials = local.dockerhub_credentials
    })

    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
    instance_types               = lookup(local.monitoring_node_size, terraform.workspace, local.monitoring_node_size["default"])
    labels = {
      Terraform                                     = "true"
      "cloud-platform.justice.gov.uk/monitoring-ng" = "true"
      Cluster                                       = terraform.workspace
      Domain                                        = local.fqdn
    }
    tags = {
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

  thanos_ng_17_12_24 = {
    desired_size = 1
    max_size     = 1
    min_size     = 1
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 200
          volume_type           = "gp3"
          iops                  = 0
          encrypted             = false
          kms_key_id            = ""
          delete_on_termination = true
        }
      }
    }


    subnet_ids = data.aws_subnets.thanos_nodegroup_az.ids
    name       = "${terraform.workspace}-thanos-ng"

    create_security_group  = false
    create_launch_template = true
    pre_bootstrap_user_data = templatefile("${path.module}/templates/user-data-140824.tpl", {
      dockerhub_credentials = local.dockerhub_credentials
    })

    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
    instance_types               = lookup(local.thanos_node_size, terraform.workspace, local.thanos_node_size["default"])
    labels = {
      "topology.kubernetes.io/zone"             = "eu-west-2a"
      Terraform                                 = "true"
      "cloud-platform.justice.gov.uk/thanos-ng" = "true"
      Cluster                                   = terraform.workspace
      Domain                                    = local.fqdn
    }
    tags = {
      monitoring_ng = "true"
      application   = "moj-cloud-platform"
      business-unit = "platforms"
    }
    taints = [
      {
        key    = "thanos-node"
        value  = true
        effect = "NO_SCHEDULE"
      }
    ]
  }
  eks_managed_node_groups = merge(
    { default_ng_16_09_24 = local.default_ng_16_09_24, monitoring_ng_19_03_25 = local.monitoring_ng_19_03_25 },
  terraform.workspace == "manager" ? { thanos_ng_17_12_24 = local.thanos_ng_17_12_24 } : {})
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"


  cluster_name              = terraform.workspace
  subnet_ids                = concat(tolist(data.aws_subnets.private.ids), tolist(data.aws_subnets.public.ids), tolist(data.aws_subnets.eks_private.ids))
  vpc_id                    = data.aws_vpc.selected.id
  cluster_version           = lookup(local.cluster_version, terraform.workspace, local.cluster_version["default"])
  enable_irsa               = true
  cluster_enabled_log_types = var.cluster_enabled_log_types

  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days
  cluster_security_group_description     = "EKS cluster security group."
  cluster_security_group_name            = terraform.workspace

  create_node_security_group = false
  node_security_group_id     = aws_security_group.node.id

  iam_role_name    = terraform.workspace
  prefix_separator = ""

  eks_managed_node_groups = local.eks_managed_node_groups

  iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  # Out of the box you can't specify groups to map, just users. Some people did some workarounds
  # we can explore later: https://ygrene.tech/mapping-iam-groups-to-eks-user-access-66fd745a6b77
  manage_aws_auth_configmap = true
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::754256621582:user/SabluMiah"
      username = "SabluMiah"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/JackStockley"
      username = "JackStockley"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/SteveWilliams"
      username = "SteveWilliams"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/TomSmith"
      username = "TomSmith"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/cloud-platform/manager-concourse"
      username = "manager-concourse"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/KyTruong"
      username = "KyTruong"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/MikeBell"
      username = "MikeBell"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/DavidElliott"
      username = "DavidElliott"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/TariqMahmood"
      username = "TariqMahmood"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/TimCheung"
      username = "TimCheung"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/FolarinOyenuga"
      username = "FolarinOyenuga"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/EmmaTerry"
      username = "EmmaTerry"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/WajidFarid"
      username = "WajidFarid"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/ZuriGuardiola"
      username = "ZuriGuardiola"
      groups   = ["system:masters"]
    }
  ]

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::754256621582:role/AWSReservedSSO_AdministratorAccess_ae2d551dbf676d8f"
      username = "{{SessionName}}"
      groups   = ["system:masters"]
    },
  ]

  tags = local.tags
}



#######################
# EKS Cluster add-ons #
#######################
module "aws_eks_addons" {
  source                  = "github.com/ministryofjustice/cloud-platform-terraform-eks-add-ons?ref=1.18.9"
  depends_on              = [module.eks.cluster]
  cluster_name            = terraform.workspace
  eks_cluster_id          = module.eks.cluster_id
  cluster_oidc_issuer_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  addon_tags              = local.tags


  addon_vpc_cni_version    = "v1.19.6-eksbuild.7"
  addon_coredns_version    = "v1.11.4-eksbuild.14"
  addon_kube_proxy_version = "v1.31.10-eksbuild.2"
}

