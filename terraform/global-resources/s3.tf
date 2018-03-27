resource "aws_s3_bucket" "platform_terraform" {
  bucket = "moj-cp-k8s-investigation-platform-terraform"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "kops_state_store" {
  bucket = "moj-cp-k8s-investigation-kops"
  acl    = "private"

  versioning {
    enabled = true
  }
}
