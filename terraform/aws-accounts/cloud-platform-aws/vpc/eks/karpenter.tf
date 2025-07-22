resource "aws_iam_role" "karpenter_cluster_role" {
  name = "KarpenterClusterRole-cp-2107-0807"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.eks.oidc_provider}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:kube-system:karpenter",
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "karpenter_controller_policy_attachment" {
  name       = "KarpenterControllerPolicyAttachment-cp-2107-0807"
  roles      = [aws_iam_role.karpenter_cluster_role.name]
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}

resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "KarpenterControllerPolicy-cp-2107-0807"
  # role = aws_iam_role.karpenter_cluster_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts",
          "sqs:GetQueueUrl",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes",
          "events:DescribeRule"
        ],
        Effect   = "Allow",
        Resource = "*",
        Sid      = "Karpenter"
      },
      {
        Action = "ec2:TerminateInstances",
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" : "*"
          }
        },
        Effect   = "Allow",
        Resource = "*",
        Sid      = "ConditionalEC2Termination"
      },
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = aws_iam_role.karpenter_node_role.arn,
        Sid      = "PassNodeIAMRole"
      },
      {
        Effect   = "Allow",
        Action   = "eks:DescribeCluster",
        Resource = module.eks.cluster_arn,
        Sid      = "EKSClusterEndpointLookup"
      },
      {
        Sid      = "AllowScopedInstanceProfileCreationActions",
        Effect   = "Allow",
        Resource = "*",
        Action = [
          "iam:CreateInstanceProfile"
        ],
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${module.eks.cluster_name}" : "owned",
            "aws:RequestTag/topology.kubernetes.io/region" : "${data.aws_region.current.name}",
          },
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileTagActions",
        Effect   = "Allow",
        Resource = "*",
        Action = [
          "iam:TagInstanceProfile"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_name}" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : "${data.aws_region.current.name}",
            "aws:RequestTag/kubernetes.io/cluster/${module.eks.cluster_name}" : "owned",
            "aws:RequestTag/topology.kubernetes.io/region" : "${data.aws_region.current.name}"
          },
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*",
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileActions",
        Effect   = "Allow",
        Resource = "*",
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ],
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_name}" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : "${data.aws_region.current.name}"
          },
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        Sid      = "AllowInstanceProfileReadActions",
        Effect   = "Allow",
        Resource = "*",
        Action   = "iam:GetInstanceProfile"
      }
    ]
  })
}

resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole-cp-2107-0807"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_role_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ])

  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = each.value
}



resource "aws_security_group" "karpenter" {
  name_prefix = terraform.workspace
  description = "Security group for all karpenter nodes in the cluster."
  vpc_id      = data.aws_vpc.selected.id
  tags = merge(
    local.tags,
    {
      "Name"                                         = "${terraform.workspace}-karpenter_sg"
      "kubernetes.io/cluster/${terraform.workspace}" = "owned"
      "karpenter.sh/discovery"                       = "cp-2107-0807"
    },
  )
}

resource "aws_security_group_rule" "karpenter_egress_internet" {
  description       = "Allow karpenter all egress to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.karpenter.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "karpenter_ingress_self" {
  description              = "Allow karpenter nodes to communicate with each other."
  protocol                 = "-1"
  security_group_id        = aws_security_group.karpenter.id
  source_security_group_id = aws_security_group.karpenter.id
  from_port                = 0
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "karpenter_ingress_cluster" {
  description              = "Allow workers pods to receive communication from the cluster control plane."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.karpenter.id
  source_security_group_id = module.eks.cluster_security_group_id
  from_port                = 1025
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "karpenter_ingress_cluster_https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.karpenter.id
  source_security_group_id = module.eks.cluster_security_group_id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}
# Create SQS queue for Karpenter interruption events
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name = "karpenter-interruption-queue-cp-2107-0807"
}

# Create EventBridge rule for EC2 interruption events
resource "aws_cloudwatch_event_rule" "karpenter_interruption_rule" {
  name = "karpenter-interruption-rule"

  event_pattern = jsonencode({
    source = ["aws.ec2"]
    "detail-type" = [
      "EC2 Spot Instance Interruption Warning",
      "EC2 Instance Rebalance Recommendation",
      "EC2 Instance State-change Notification"
    ]
  })
}

# Attach the SQS queue as a target of the EventBridge rule
resource "aws_cloudwatch_event_target" "karpenter_target" {
  rule      = aws_cloudwatch_event_rule.karpenter_interruption_rule.name
  target_id = "karpenter-sqs-target"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

# Allow EventBridge to send messages to the SQS queue
resource "aws_sqs_queue_policy" "karpenter_sqs_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      }
    ]
  })
}

resource "aws_security_group" "karpenter_cluster_additional" {
  name_prefix = terraform.workspace
  description = "SG tp let karpenter nodes talk to cluster control plane."
  vpc_id      = data.aws_vpc.selected.id
  tags        = local.tags
}

resource "aws_security_group_rule" "cluster_additional_egress" {
  description       = "Allow nodes all egress to the Internet."
  protocol          = "-1"
  security_group_id = aws_security_group.karpenter_cluster_additional.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "karpenter_cluster_additional" {
  description              = "Allow karpenter nodes to communicate with cluster over 443"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.karpenter_cluster_additional.id
  source_security_group_id = aws_security_group.karpenter.id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}
