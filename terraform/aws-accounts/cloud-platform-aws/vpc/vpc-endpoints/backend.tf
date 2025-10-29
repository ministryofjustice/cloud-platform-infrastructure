terraform {
  backend "s3" {
    bucket  = "cloud-platform-terraform-state"
    key     = "vpc-endpoints/terraform.tfstate"
    region  = "eu-west-1"
    profile = "moj-cp"
  }
}
