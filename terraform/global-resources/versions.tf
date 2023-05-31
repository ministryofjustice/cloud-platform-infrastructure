terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "0.41.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.1"
    }
    elasticsearch = {
      source  = "phillbaker/elasticsearch"
      version = "2.0.7"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
  required_version = ">= 1.2.5"
}
