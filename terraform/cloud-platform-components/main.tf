terraform {
  backend "s3" {
    bucket               = "cloud-platform-components-terraform"
    region               = "eu-west-1"
    workspace_key_prefix = "helm:"
    key                  = "terraform.tfstate"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"

  # config_context_cluster = "${terraform.workspace}"
}

data "terraform_remote_state" "cluster" {
  backend = "s3"

  config {
    bucket = "moj-cp-k8s-investigation-platform-terraform"
    region = "eu-west-1"
    key    = "env:/${terraform.workspace}/terraform.tfstate"
  }
}
