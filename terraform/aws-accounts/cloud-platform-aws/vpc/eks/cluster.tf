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
  dockerhub_credentials = "${var.dockerhub_user}:${var.dockerhub_token}"
  dockerhub_file        = <<-EOD
  {
    "auths": {
      "https://index.docker.io/v1/": {
        "auth": "${base64encode(local.dockerhub_credentials)}"
      }
    }
  }
EOD
  pre_userdata          = <<-EOD
  mkdir -p "/root/.docker"
  echo '${local.dockerhub_file}' > "/root/.docker/config.json"
  mkdir -p "/var/lib/kubelet/.docker"
  echo '${local.dockerhub_file}' > "/var/lib/kubelet/config.json"
EOD
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v15.2.0"

  cluster_name     = local.cluster_name
  subnets          = concat(tolist(data.aws_subnet_ids.private.ids), tolist(data.aws_subnet_ids.public.ids))
  vpc_id           = data.aws_vpc.selected.id
  write_kubeconfig = false
  cluster_version  = "1.18"
  enable_irsa      = true

  node_groups = {
    the_ng = {
      desired_capacity = local.is_live_eks_cluster ? 19 : 4
      max_capacity     = 30
      min_capacity     = local.is_live_eks_cluster ? 19 : 1
      subnets          = data.aws_subnet_ids.private.ids

      create_launch_template = true
      pre_userdata           = local.pre_userdata

      instance_type = local.is_manager_cluster ? "m4.xlarge" : "r5.xlarge"
      k8s_labels = {
        Terraform = "true"
        Cluster   = local.cluster_name
        Domain    = local.cluster_base_domain_name
      }
      additional_tags = {
        application   = "moj-cloud-platform"
        business-unit = "platforms"
        is_production = local.is_manager_cluster || local.is_live_eks_cluster ? "true" : "false"
        default_ng    = "true"
      }
    }
  }

  # Out of the box you can't specify groups to map, just users. Some people did some workarounds
  # we can explore later: https://ygrene.tech/mapping-iam-groups-to-eks-user-access-66fd745a6b77
  map_users = [
    {
      userarn  = "arn:aws:iam::754256621582:user/AlejandroGarrido"
      username = "AlejandroGarrido"
      groups   = ["system:masters"]
    },
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
      userarn  = "arn:aws:iam::754256621582:user/cloud-platform/manager-concourse"
      username = "manager-concourse"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::754256621582:user/VijayVeeranki"
      username = "VijayVeeranki"
      groups   = ["system:masters"]
    }
  ]

  tags = {
    Terraform = "true"
    Cluster   = local.cluster_name
    Domain    = local.cluster_base_domain_name
  }
}
