
module "cert_manager" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-certmanager?ref=0.0.2"

  iam_role_nodes      = data.aws_iam_role.nodes.arn
  cluster_domain_name = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  hostzone            = lookup(var.cluster_r53_resource_maps, terraform.workspace, ["arn:aws:route53:::hostedzone/${data.terraform_remote_state.cluster.outputs.hosted_zone_id}"])


  # This module requires helm and OPA already deployed
  dependence_prometheus = module.prometheus.helm_prometheus_operator_status
  dependence_deploy     = null_resource.deploy
  dependence_opa        = module.opa.helm_opa_status
}
