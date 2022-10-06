variable "dockerhub_user" {
  description = "DockerHub user for the Cloud Platform (see LastPass). This is required to avoid hitting limits when pulling images."
  type        = string
}

variable "dockerhub_token" {
  description = "DockerHub token for the Cloud Platform user"
  type        = string
}

variable "enable_oidc_associate" {
  description = "Enable OIDC associate provider. This takes approximately 30 minutes to complete, so be prepared to wait."
  default = true
  type = bool
}

variable "auth0_issuerUrl" {
  description = "Domain issuer URL by which Auth0 can find the OpenID Provider Configuration Document"
  default     = "https://justice-cloud-platform.eu.auth0.com/"
  type        = string
}

# Set when Auth0 account is setup in here: /terraform/global-resources/auth0.tf
variable "auth0_groupsClaim" {
  description = "OIDC Group Claim domain for justice cloud-platform account"
  default     = "https://k8s.integration.dsd.io/groups"
  type        = string
}

variable "cluster_enabled_log_types" {
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  description = "A list of the desired control plane logging to enable."
  type        = list(string)
}

variable "cluster_log_retention_in_days" {
  default     = 400 # Slightly over three months as per security advice https://security-guidance.service.justice.gov.uk/logging-and-monitoring/#log-retention
  description = "Number of days to retain log events. Default retention - 90 days."
  type        = number
}
