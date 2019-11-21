variable "team_name" {
  description = "The team creating the resource"
  default     = "cloud-platform"
}

variable "business_unit" {
  description = " Area of the MOJ responsible for the service"
  default     = "mojdigital"
}

variable "infrastructure_support" {
  description = "The team responsible for managing the infrastructure. Should be of the form <team-name> (<team-email>)"
  default     = "platform@digital.justice.gov.uk"
}

variable "cloudtrail_bucket_name" {
  default = "cloud-platform-cloudtrail"
}

variable "slack_config_cloudwatch_lp" {
  description = "Add Slack webhook API URL for integration with slack."
}

