# # moved worker node security group out of eks module

# moved { 
#     from = module.eks.aws_security_group.workers
#     to = aws_security_group.workers
# }


resource "aws_security_group" "workers" {

  name_prefix = terraform.workspace
  description = "Security group for all nodes in the cluster."
  vpc_id      = data.aws_vpc.selected.id
  tags = merge(
    local.tags,
    {
      "Name"                                      = "${terraform.workspace}-eks_worker_sg"
      "kubernetes.io/cluster/${terraform.workspace}" = "owned"
    },
  )
}

resource "aws_security_group_rule" "workers_egress_internet" {

  description       = "Allow nodes all egress to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.workers.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "workers_ingress_self" {

  description              = "Allow node to communicate with each other."
  protocol                 = "-1"
  security_group_id = aws_security_group.workers.id
  source_security_group_id = aws_security_group.workers.id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster" {

  description              = "Allow workers pods to receive communication from the cluster control plane."
  protocol                 = "tcp"
  security_group_id = aws_security_group.workers.id
  source_security_group_id = module.eks.cluster_security_group_id
  from_port                = 1025
  to_port                  = 65535
  type                     = "ingress"
}

# resource "aws_security_group_rule" "workers_ingress_cluster_kubelet" {


#   description              = "Allow workers Kubelets to receive communication from the cluster control plane."
#   protocol                 = "tcp"
#   security_group_id = aws_security_group.workers.id
#   source_security_group_id = module.eks.cluster_security_group_id
#   from_port                = 10250
#   to_port                  = 10250
#   type                     = "ingress"
# }

resource "aws_security_group_rule" "workers_ingress_cluster_https" {


  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane."
  protocol                 = "tcp"
  security_group_id = aws_security_group.workers.id
  source_security_group_id = module.eks.cluster_security_group_id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

#  cluster security group rule for worker node security group - https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/main.tf#L90C1-L100C2

resource "aws_security_group_rule" "cluster_https_worker_ingress" {

  description              = "Allow pods to communicate with the EKS cluster API."
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.workers.id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}
# resource "aws_security_group_rule" "workers_ingress_cluster_primary" {


#   description              = "Allow pods running on workers to receive communication from cluster primary security group (e.g. Fargate pods)."
#   protocol                 = "all"
#   security_group_id = aws_security_group.workers.id
#   source_security_group_id = local.cluster_primary_security_group_id
#   from_port                = 0
#   to_port                  = 65535
#   type                     = "ingress"
# }

# resource "aws_security_group_rule" "cluster_primary_ingress_workers" {


#   description              = "Allow pods running on workers to send communication to cluster primary security group (e.g. Fargate pods)."
#   protocol                 = "all"
#   security_group_id = aws_security_group.workers.id
#   source_security_group_id = local.worker_security_group_id
#   from_port                = 0
#   to_port                  = 65535
#   type                     = "ingress"
# }

