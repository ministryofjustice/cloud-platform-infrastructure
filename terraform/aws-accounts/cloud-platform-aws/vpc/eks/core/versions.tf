terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.35.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.2"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.4"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.2"
    }
  }
  required_version = ">= 1.2.5"
}

