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

resource "aws_key_pair" "sandbox" {
  key_name   = "kubernetes-sandbox"
  public_key = "${file("../ssh/kubernetes_sandbox_id_rsa.pub")}"
}
