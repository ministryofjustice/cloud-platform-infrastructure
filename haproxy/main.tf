provider "aws" {
  region  = "${var.aws_region}"
  version = "<1.43.0"
}

resource "random_id" "id" {
  byte_length = 4
}
