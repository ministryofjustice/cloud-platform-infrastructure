module "eks_csi" {
  source      = "github.com/ministryofjustice/cloud-platform-terraform-eks-csi?ref=1.2.2"
  eks_cluster = terraform.workspace
}