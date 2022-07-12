terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=4.20.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "=2.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "=1.13.4"
    }
  }
  required_version = ">= 0.14"
}
