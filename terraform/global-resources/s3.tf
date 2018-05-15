resource "aws_s3_bucket" "platform_terraform" {
  bucket = "${var.project_name}-platform-terraform"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "kops_state_store" {
  bucket = "${var.project_name}-kops"
  acl    = "private"

  versioning {
    enabled = true
  }
}
