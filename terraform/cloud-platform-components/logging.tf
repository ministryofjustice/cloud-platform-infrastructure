
module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=0.0.2"

  # if you need to connect to the test elasticsearch cluster, replace "placeholder-elasticsearch" with "search-cloud-platform-test-zradqd7twglkaydvgwhpuypzy4.eu-west-2.es.amazonaws.com"
  # -> value = "${replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com" : "search-cloud-platform-test-zradqd7twglkaydvgwhpuypzy4.eu-west-2.es.amazonaws.com"
  # Your cluster will need to be whitelisted.
  elasticsearch_host       = replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-live-dibidbfud3uww3lpxnhj2jdws4.eu-west-2.es.amazonaws.com" : "placeholder-elasticsearch"
  elasticsearch_audit_host = replace(terraform.workspace, "live", "") != terraform.workspace ? "search-cloud-platform-audit-dq5bdnjokj4yt7qozshmifug6e.eu-west-2.es.amazonaws.com" : ""

  dependence_prometheus       = module.prometheus.helm_prometheus_operator_status
  dependence_deploy           = null_resource.deploy
  dependence_priority_classes = null_resource.priority_classes
}
