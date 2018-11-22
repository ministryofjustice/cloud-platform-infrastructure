variable "team_name" {}

variable "business-unit" {
  description = " Area of the MOJ responsible for the service"
  default     = "mojdigital"
}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
}

variable "terraform_bucket_name" {
  default = "cloud-platform-cloudtrail-tf-state"
}

variable "cloudtrail_bucket_name" {
    default = "cp-cloudtrail-bucket"
}