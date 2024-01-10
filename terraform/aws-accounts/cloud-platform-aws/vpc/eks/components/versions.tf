terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.1"
    }
  }
  required_version = ">= 1.2.5"
}
