terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "cloud-platform-components"
    profile              = "moj-cp"
  }
}

provider "aws" {
  profile = "moj-pi"
}

provider "kubernetes" {}

provider "helm" {
  kubernetes {}
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config {
    bucket  = "cloud-platform-terraform-state"
    region  = "eu-west-1"
    key     = "cloud-platform/${terraform.workspace}/terraform.tfstate"
    profile = "moj-cp"
  }
}
