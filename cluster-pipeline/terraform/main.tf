terraform {
  backend "s3" {
    bucket = "moj-cp-cluster-creation-pipeline-terraform"
    key    = "terraform.tfstate"
    region = "${var.region}"
  }
}

provider "aws" {
  version = "~> 1.9.0"
  region = "${var.region}"
}
