terraform {
  backend "s3" {
    bucket = "moj-cp-k8s-investigation-terraform"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  version = "~> 1.1"
  region = "eu-west-1"
}
