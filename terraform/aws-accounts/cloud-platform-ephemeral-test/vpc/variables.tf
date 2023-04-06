variable "availability_zones" {
  type        = list(string)
  description = "a list of EC2 availability zones"
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "cluster_names" {
  description = "A list of every Kubernetes cluster present in the VPC"
  type        = list(string)
  default     = []
}

variable "base_domain_name" {
  description = "Base domain name for the VPC"
  type        = string
  default     = "ephemeral-test.cloud-platform.service.justice.gov.uk"
}
