variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
}

variable "slack_config" {
  description = "Add Slack webhook API URL and channel for integration with slack."
}

variable "slack_config_laa-cla-fala" {
  description = "Add Slack webhook API URL and channel for integration with slack."
}

variable "slack_config_prisoner-money" {
  description = "Add Slack webhook API URL and channel for integration with slack."
}

variable "auth0_client_id" {
  description = "The client id of the Auth0 application."
}

variable "auth0_client_secret" {
  description = "The client secret of the Auth0 application."
}

variable "auth0_domain" {
  description = "The endpoint URL of the tenant without sub-domains."
}