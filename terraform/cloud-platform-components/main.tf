terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-components"
  }
}

provider "kubernetes" {
  version     = "~> 1.3"
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

data "terraform_remote_state" "cluster" {
  backend   = "s3"

  config {
    bucket = "cloud-platform-terraform-state"
    region = "eu-west-1"
    key    = "cloud-platform/${terraform.workspace}/terraform.tfstate"
  }
}
