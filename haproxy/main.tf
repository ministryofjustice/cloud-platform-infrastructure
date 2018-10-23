terraform {
  backend "s3" {
    bucket = "cp-test-haproxy"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}
