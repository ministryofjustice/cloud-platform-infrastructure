resource "aws_s3_bucket" "platform_terraform" {
  bucket = "moj-cp-k8s-investigation-platform-terraform"
  acl    = "private"

  versioning {
    enabled = true
  }
}
