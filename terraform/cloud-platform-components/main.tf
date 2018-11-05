terraform {
  backend "s3" {
    bucket = "cloud-platform-components-terraform"
    region = "eu-west-1"
    key    = "terraform.tfstate"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
