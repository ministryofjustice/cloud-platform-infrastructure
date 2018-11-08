terraform {
  backend "s3" {
    bucket = "cloud-platform-haproxy-terraform"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  region  = "${var.aws_region}"
  version = ">=1.34"
}

resource "random_id" "id" {
  byte_length = 4
}
