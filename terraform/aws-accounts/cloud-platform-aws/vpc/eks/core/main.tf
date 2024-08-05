############################
# Backend & Provider setup #
############################

terraform {
  backend "s3" {
    bucket               = "cloud-platform-terraform-state"
    region               = "eu-west-1"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "aws-accounts/cloud-platform-aws/vpc/eks/core"
    profile              = "moj-cp"
    dynamodb_table       = "cloud-platform-terraform-state"
  }
}

variable "force_fail" {
  description = "force fail tf plan"
  type        = bool
  default     = true
}

resource "null_resource" "force_fail" {
  count = var.force_fail ? 0 : -1
}