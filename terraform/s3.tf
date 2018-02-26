resource "aws_s3_bucket" "kops_state_store" {
  bucket = "moj-cp-k8s-investigation-kops"
  acl    = "private"

  versioning {
    enabled = true
  }
}
