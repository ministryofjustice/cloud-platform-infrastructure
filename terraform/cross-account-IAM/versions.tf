terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.68.0"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.11"
    }
  }
  required_version = ">= 0.13"
}
