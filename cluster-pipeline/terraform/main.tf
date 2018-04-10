terraform {
  backend "s3" {
    bucket = "moj-cp-cluster-creation-pipeline-terraform"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  version = "~> 1.9.0"
  region = "eu-west-1"
}
