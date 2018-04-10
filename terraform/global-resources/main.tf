terraform {
  backend "s3" {
    bucket = "${var.project_name}-global-terraform"
    region = "${var.region}"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  version = "~> 1.9.0"
  region  = "${var.region}"
}
