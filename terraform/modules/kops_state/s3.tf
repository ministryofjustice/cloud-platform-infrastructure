resource "aws_s3_bucket" "kops_state_store" {
  bucket = "moj-cp-kops-${var.cluster_name}"
  acl    = "private"

  versioning {
    enabled = true
  }
}
