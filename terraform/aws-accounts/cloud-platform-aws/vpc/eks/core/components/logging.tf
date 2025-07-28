module "logging" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-logging?ref=1.26.7"

  opensearch_app_host = lookup(var.opensearch_app_host_map, terraform.workspace, "placeholder-opensearch")
  elasticsearch_host  = lookup(var.elasticsearch_hosts_maps, terraform.workspace, "placeholder-elasticsearch")

  depends_on = [
    module.label_pods_controller
  ]

  # Required variables for tags in S3-Bucket submodule
  business_unit = local.default_tags["business-unit"]
  application   = local.default_tags["application"]
  is_production = local.default_tags["is-production"]
  team_name     = local.default_tags["owner"]
}
