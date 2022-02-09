terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.68.0"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6.1"
    }
    null = {
      source = "hashicorp/null"
    }
    template = {
      source = "hashicorp/template"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
  required_version = ">= 0.14"
}
