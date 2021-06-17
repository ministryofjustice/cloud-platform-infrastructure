variable "dockerhub_user" {
  description = "Cloud platform user (see lastpass). This is required to avoid hitting limits when pulling images."
}

variable "dockerhub_token" {
  description = "Token for the above"
}
variable "auth0_issuerUrl" {
  description = "domain IssuerURL by which Auth0 can find the OpenID Provider Configuration Document"
  default = "https://justice-cloud-platform.eu.auth0.com/"
}

# Set when Auth0 account is setup in here: /terraform/global-resources/auth0.tf
variable "auth0_groupsClaim" {
  description = "OIDC Group Claim domain for justice cloud-platform account"
  default = "https://k8s.integration.dsd.io/groups"
}

variable "check_associate" {
  description = "Check for active association during cluster creation. This is required for kuberos to authenticate to the cluster."
  default = "true"
}