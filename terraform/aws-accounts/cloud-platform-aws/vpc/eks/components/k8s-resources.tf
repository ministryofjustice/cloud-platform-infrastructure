########
# CSIs #
########

module "eks_csi" {
  source      = "github.com/ministryofjustice/cloud-platform-terraform-eks-csi?ref=gp3"
  eks_cluster = terraform.workspace
}

module "efs_csi" {
  source      = "github.com/ministryofjustice/cloud-platform-terraform-efs-csi?ref=1.0.1"
  eks_cluster = terraform.workspace
}

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

resource "kubernetes_storage_class" "io1" {
  metadata {
    name = "io1-expand"
  }

  storage_provisioner    = "kubernetes.io/aws-ebs"
  reclaim_policy         = "Delete"
  allow_volume_expansion = "true"

  parameters = {
    type      = "io1"
    iopsPerGB = "10000"
    fsType    = "ext4"
  }
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

  depends_on = [module.eks_csi]
}

# remvove default from GP2
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
  metadata {
    name      = "concourse-build-environments"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "concourse_build_environments" {
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
