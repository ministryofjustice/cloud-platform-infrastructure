terraform {
  required_version = ">= 1.2.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.87.0"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.12.0"
    }
    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "~> 2.0.7"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.3.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4.1"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.5.0"
    }
  }
}
