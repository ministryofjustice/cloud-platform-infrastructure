##########################################
# EKS Worker node Security Group & Rules #
##########################################

# As of EKS module upgrade 17.24.0 > 18.31.2 we are managing worker node security group & associated rules outside of the EKS module
# in order to retain control of additional rules required for node communication.

# Ref: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/workers.tf#L377

resource "aws_security_group" "node" {
  name_prefix = terraform.workspace
  description = "Security group for all nodes in the cluster."
  vpc_id      = data.aws_vpc.selected.id
  tags = merge(
    local.tags,
    {
      "Name"                                         = "${terraform.workspace}-eks_worker_sg"
      "kubernetes.io/cluster/${terraform.workspace}" = "owned"
    },
  )
}

resource "aws_security_group_rule" "node_egress_internet" {
  description       = "Allow nodes all egress to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "node_ingress_self" {
  description              = "Allow node to communicate with each other."
  protocol                 = "-1"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.node.id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  description              = "Allow workers pods to receive communication from the cluster control plane."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = module.eks.cluster_security_group_id
  from_port                = 1025
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "node_ingress_cluster_https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = module.eks.cluster_security_group_id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

# Cluster security group rule for worker node security group - https://github.com/terraform-aws-modules/terraform-aws-eks/blob/v17.24.0/main.tf#L90C1-L100C2
resource "aws_security_group_rule" "cluster_https_node_ingress" {
  description              = "Allow pods to communicate with the EKS cluster API."
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.node.id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}