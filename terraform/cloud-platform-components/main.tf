terraform {
  backend "s3" {
    bucket = "cloud-platform-components-terraform"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

provider "kubernetes" {
  version = "~> 1.3"
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

data "terraform_remote_state" "cluster" {
  backend   = "s3"
  workspace = "${terraform.workspace}"

  config {
    bucket = "moj-cp-k8s-investigation-platform-terraform"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}
