terraform {
  backend "s3" {
    bucket = "cloud-platform-s3-terraform-state"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-west-1"
}
