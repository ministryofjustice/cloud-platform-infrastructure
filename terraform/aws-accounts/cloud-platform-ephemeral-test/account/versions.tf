terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 0.34.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.68.0"
    }
    github = {
      source = "integrations/github"
    }
    curl = {
      source  = "anschoewe/curl"
      version = "~> 0.1.4"
    }
  }
  required_version = ">= 0.14"
}
