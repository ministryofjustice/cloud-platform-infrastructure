terraform {
  backend "s3" {
    bucket = "moj-cp-k8s-investigation-global-terraform"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  version = "~> 1.9.0"
  region  = "eu-west-1"
}
