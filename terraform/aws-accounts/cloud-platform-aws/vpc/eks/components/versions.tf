terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.13.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.3.0"
    }
  }
  required_version = ">= 1.2.5"
}
