resource "aws_s3_bucket" "kops_state_store" {
  bucket = "moj-cp-k8s-investigation-kops"
  acl    = "private"

  versioning {
    enabled = true
  }
}
# To allow us to store kubeconfig data for pipeline
resource "aws_s3_bucket" "cluster_keystore" {
  bucket = "non-production-cluster-keystore"
  acl    = "private"

  versioning {
    enabled = true
  }
}
