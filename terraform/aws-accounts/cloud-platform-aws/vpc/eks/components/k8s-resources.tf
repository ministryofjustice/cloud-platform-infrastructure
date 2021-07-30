###################
# Storage Classes #
###################

resource "kubernetes_storage_class" "storageclass" {

  metadata {
    name = "gp2-expand"
  }

  storage_provisioner    = "kubernetes.io/aws-ebs"
  reclaim_policy         = "Delete"
  allow_volume_expansion = "true"

  parameters = {
    type      = "gp2"
    encrypted = "true"
  }
}

data "aws_iam_policy_document" "ebs_doc" {
  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:DetachVolume",
      "ec2:DeleteVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DeleteSnapshot",
      "ec2:DescribeSnapshots",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "sts:AssumeRoleWithWebIdentity"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ebs_policy" {
  name        = "eks-csi-policy-${terraform.workspace}"
  path        = "/cloud-platform/"
  policy      = data.aws_iam_policy_document.ebs_doc.json
  description = "Policy for EKS CSI driver"
}

module "ebs_irsa" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-irsa?ref=role-name"

  eks_cluster      = terraform.workspace
  namespace        = "kube-system"
  service_account  = "ebs-csi-controller-sa"
  role_policy_arns = [aws_iam_policy.ebs_policy.arn]
}

resource "helm_release" "aws_ebs" {
  name       = "aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.0.3"

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  depends_on = [module.ebs_irsa]
}

resource "kubernetes_storage_class" "storageclass_gp3" {

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = "true"

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [helm_release.aws_ebs]
}

# mini-hack to remove the default from GP2 because otherwise terraform tries (and fails) to create the storageclass again
resource "kubectl_manifest" "change_sc_default" {
  depends_on = [kubernetes_storage_class.storageclass_gp3]
  yaml_body  = <<YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
  name: gp2
parameters:
  fsType: ext4
  type: gp2
provisioner: kubernetes.io/aws-ebs
volumeBindingMode: WaitForFirstConsumer
YAML
}

####################
# Priority Classes #
####################

resource "kubernetes_priority_class" "cluster_critical" {
  metadata {
    name = "cluster-critical"
  }

  value          = 999999000
  description    = "This priority class is meant to be used as the system-cluster-critical class, outside of the kube-system namespace."
  global_default = false
}

resource "kubernetes_priority_class" "node_critical" {
  metadata {
    name = "node-critical"
  }

  value          = 1000000000
  description    = "This priority class is meant to be used as the system-node-critical class, outside of the kube-system namespace."
  global_default = false
}

########
# RBAC #
########

resource "kubernetes_cluster_role_binding" "webops" {
  metadata {
    name = "webops-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "Group"
    name      = "github:webops"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_service_account" "concourse_build_environments" {
  count = lookup(local.prod_workspace, terraform.workspace, false) ? 1 : 0

  metadata {
    name      = "concourse-build-environments"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "concourse_build_environments" {
  count = lookup(local.prod_workspace, terraform.workspace, false) ? 1 : 0

  metadata {
    name = "concourse-build-environments"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "concourse-build-environments"
    namespace = "kube-system"
  }
}
