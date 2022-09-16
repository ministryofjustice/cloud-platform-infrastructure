########
# CSIs #
########

module "efs_csi" {
  source      = "github.com/ministryofjustice/cloud-platform-terraform-efs-csi?ref=1.0.1"
  eks_cluster = terraform.workspace
  depends_on  = [helm_release.calico]
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
