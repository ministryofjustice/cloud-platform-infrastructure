########
# CSIs #
########

module "eks_csi" {
  source      = "github.com/ministryofjustice/cloud-platform-terraform-eks-csi?ref=1.2.0"
  eks_cluster = terraform.workspace
  depends_on  = [module.tigera_calico]
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
    iopsPerGB = "26"
    fsType    = "ext4"
  }
}

resource "kubernetes_storage_class" "storageclass_gp3" {
  depends_on = [module.eks_csi]
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
