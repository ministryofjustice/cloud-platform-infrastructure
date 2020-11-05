
provider "aws" {
  region = "eu-west-1"
}

module "tf_states_backend" {
  # source = "github.com/ministryofjustice/cloud-platform-terraform-tfstate-backend?ref=0.0.1"
  source = "/home/mogaal/workspace/github/ministryofjustice/cloud-platform-terraform-tfstate-backend"

  s3_bucket_name = "cloud-platform-terraform-state"
  region = "eu-west-1"
  dynamo_table_name = "cloud-platform-terraform-state"
}

