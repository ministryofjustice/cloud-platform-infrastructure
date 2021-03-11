terraform {
  required_providers {
    auth0 = {
      source = "alexkappa/auth0"
    }
    aws = {
      source = "hashicorp/aws"
    }
    external = {
      source = "hashicorp/external"
    }
    http = {
      source = "hashicorp/http"
    }
  }
  required_version = ">= 0.13"
}
