terraform {
  required_version = ">= 1.2.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.1"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 0.48.0"
    }
    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "~> 2.0.7"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.23.0"
    }
  }
}
