module "velero" {
  source                = "github.com/ministryofjustice/cloud-platform-terraform-velero?ref=0.0.2"
  iam_role_nodes        = data.aws_iam_role.nodes.arn
  dependence_prometheus = module.prometheus.helm_prometheus_operator_status
  cluster_domain_name   = data.terraform_remote_state.cluster.outputs.cluster_domain_name
}