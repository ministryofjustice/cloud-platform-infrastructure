terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0.2"
    }
    null = {
      source = "hashicorp/null"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.11.2"
    }
  }
  required_version = ">= 0.14"
}
