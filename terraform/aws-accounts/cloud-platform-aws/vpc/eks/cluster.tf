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
  # desired_capcity change is a manual step after initial cluster creation (when no cluster-autoscaler)
  # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/835
  node_groups_count = {
    live    = "1"
    live-2  = "1"
    manager = "1"
    default = "1"
  }
  # Default node group minimum capacity 
  default_ng_min_count = {
    live    = "1"
    live-2  = "1"
    manager = "1"
    default = "1"
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

  default_ng = {
    desired_capacity     = lookup(local.node_groups_count, terraform.workspace, local.node_groups_count["default"])
    max_capacity         = 1
    min_capacity         = lookup(local.default_ng_min_count, terraform.workspace, local.default_ng_min_count["default"])
    subnets              = ["subnet-23459843", "subnet-13b030c7", "subnet-23459843"]
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
    desired_capacity = 1
    max_capacity     = 1
    min_capacity     = 1
    subnets          = ["subnet-23459843"]

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

  tags = {
    Terraform = "true"
    Cluster   = terraform.workspace
    Domain    = local.fqdn
  }

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.24.0"

  cluster_name                  = terraform.workspace
  subnets                       = ["subnet-23459843", "subnet-13b030c7", "subnet-23459843"]
  vpc_id                        = data.aws_vpc.selected.id
  write_kubeconfig              = false
  cluster_version               = lookup(local.cluster_version, terraform.workspace, local.cluster_version["default"])
  enable_irsa                   = false
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
      userarn  = "arn:aws:iam::000000000000:user/RazvanCosma"
      username = "RazvanCosma"
      groups   = ["system:masters"]
    }
  ]

  tags = local.tags
}

#######################
# EKS Cluster add-ons #
#######################
module "aws_eks_addons" {
  count                   = 0
  source                  = "github.com/ministryofjustice/cloud-platform-terraform-eks-add-ons?ref=1.2.1"
  depends_on              = [module.eks.cluster]
  cluster_name            = terraform.workspace
  eks_cluster_id          = module.eks.cluster_id
  cluster_oidc_issuer_url = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  addon_tags              = local.tags
}
