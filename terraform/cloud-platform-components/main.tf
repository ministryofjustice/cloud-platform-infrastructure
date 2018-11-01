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
