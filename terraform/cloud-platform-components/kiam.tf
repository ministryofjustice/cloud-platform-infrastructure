
module "kiam" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-kiam?ref=0.0.1"

  # This module requires prometheus and OPA already deployed
  dependence_prometheus = module.prometheus.helm_prometheus_operator_status
  dependence_opa        = module.opa.helm_opa_status
}

