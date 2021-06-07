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
      version = "~> 1.11.1"
    }
    null = {
      source = "hashicorp/null"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.11.1"
    }
  }
  required_version = ">= 0.14"
}
