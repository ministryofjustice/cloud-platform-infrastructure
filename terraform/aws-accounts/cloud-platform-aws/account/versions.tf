terraform {
  required_version = ">= 1.2.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18.0"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.32.0"
    }
    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "~> 2.0.7"
    }
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "2.3.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.7.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
}
