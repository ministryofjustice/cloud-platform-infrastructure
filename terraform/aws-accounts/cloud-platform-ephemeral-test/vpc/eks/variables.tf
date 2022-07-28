variable "dockerhub_user" {
  description = "Cloud platform user (see lastpass). This is required to avoid hitting limits when pulling images."
}

variable "dockerhub_token" {
  description = "Token for the above"
}

variable "vpc_name" {
  description = "The VPC name where the cluster(s) are going to be provisioned. VPCs are created in cloud-platform-network"
  default     = ""
}

variable "auth0_issuerUrl" {
  description = "domain IssuerURL by which Auth0 can find the OpenID Provider Configuration Document"
  default     = "https://justice-cloud-platform.eu.auth0.com/"
}

# Set when Auth0 account is setup in here: /terraform/global-resources/auth0.tf
variable "auth0_groupsClaim" {
  description = "OIDC Group Claim domain for justice cloud-platform account"
  default     = "https://k8s.integration.dsd.io/groups"
}

variable "auth0_tenant_domain" {
  description = "This is the auth0 tenant domain"
  default     = "justice-cloud-platform.eu.auth0.com"
}

variable "cluster_enabled_log_types" {
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  description = "A list of the desired control plane logging to enable."
  type        = list(string)
}

variable "cluster_log_retention_in_days" {
  default     = 3
  description = "Number of days to retain log events. Default retention - 3 days."
  type        = number
}
