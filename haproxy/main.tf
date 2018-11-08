provider "aws" {
  region  = "${var.aws_region}"
  version = ">=1.34"
}

resource "random_id" "id" {
  byte_length = 4
}
