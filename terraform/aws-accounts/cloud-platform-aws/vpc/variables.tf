variable "availability_zones" {
  type        = list(string)
  description = "List of EC2 availability zones"
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "cluster_names" {
  description = "List of Clusters within Live-1 VPC"
  default = {
    live-1 = ["live-1.cloud-platform.service.justice.gov.uk", "manager", "live"]
  }
  type = object({
    live-1 = list(string)
  })
}


variable "profile_name" {
  type        = string
  description = "profile name used to generate new sso credentials"
  default     = "moj-cp"
}