variable "pagerduty_config" {
  description = "Add PagerDuty key to allow integration with a PD service."
  type        = string
  default = ""
}

variable "alertmanager_slack_receivers" {
  description = "A list of configuration values for Slack receivers"
  type        = list(any)

  default = [{ severity = "dummy", webhook = "https://dummy.slack.com", channel = "#dummy-alarms" }]
}

variable "elasticsearch_hosts_maps" {
  description = "Cloud Platform ElasticSearch hosts for each Terraform workspace"

  default = {
    manager = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
    live    = "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com"
    live-2  = "search-cloud-platform-live-2-y3xuoui3qenhfpmiulk4wthw5i.eu-west-2.es.amazonaws.com"
  }

  type = object({
    manager = string
    live    = string
    live-2  = string
  })
}
