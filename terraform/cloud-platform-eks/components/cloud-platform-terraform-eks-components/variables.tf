
variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
  type        = string
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = list
}

variable "cloud_platform_slack_webhook" {
  description = "Slack webhook to pass it to  script to send alerts"
}

###########
# Enables #
###########

variable "enable_metrics_server" {
  description = "Install metrics server helm chart"
  type        = bool
  default     = true
}

variable "enable_nginx_ingress_acme" {
  description = "Install nginx-ingress-controller helm chart"
  type        = bool
  default     = true
}

variable "enable_kube2iam" {
  description = "Install kube2iam helm chart"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Enable or not externalDNS Chart"
  type        = bool
  default     = true
}

variable "enable_eventrouter" {
  description = "Enable or not eventrouter Chart"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable or not the cluster-autoscaler package deployment"
  type        = bool
  default     = true
}
