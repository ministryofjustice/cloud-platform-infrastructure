module "external_dns" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-external-dns?ref=1.20.1"

  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzones           = lookup(local.hostzones, terraform.workspace, local.hostzones["default"])
  domain_filters      = lookup(local.domain_filters, terraform.workspace, local.domain_filters["default"])


  # For tuning external_dns config for production vs test clusters
  is_live_cluster = lookup(local.prod_workspace, terraform.workspace, false) || terraform.workspace == "live-2"

  eks_cluster_oidc_issuer_url = data.terraform_remote_state.cluster.outputs.cluster_oidc_issuer_url
}

module "external_dns" {
  source = "github.com/ministryofjustice/container-platform-terraform-external-dns?ref=0.1.0"

  eks_cluster_name = "live"

  required_inputs = {
    live = {
      version                 = "1.21.1"
      domain_name_prefix      = "envoy"
      sync_interval           = "60m"
      aws_zone_cache_duration = "2h"
      log_level               = "info"
    }
  }
  tags = {
    application   = "External DNS"
    business-unit = "OCTO"
    owner         = "Container Platform: External DNS"
    service-area  = "Hosting"
    source-code   = "https://github.com/ministryofjustice/container-platform-terraform-external-dns"
    slack-channel = "cloud-platform"
    is-production = "true"
  }
}