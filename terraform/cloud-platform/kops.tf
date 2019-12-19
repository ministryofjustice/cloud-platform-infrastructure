resource "local_file" "kops" {
  content  = data.template_file.kops.rendered
  filename = "../../kops/${terraform.workspace}.yaml"
}

resource "aws_kms_key" "kms" {
  description = "Creates KMS key for etcd volume encryption"
}

data "template_file" "kops" {
  template = file("./templates/kops.yaml.tpl")

  vars = {
    cluster_domain_name                  = local.cluster_base_domain_name
    cluster_node_count                   = local.is_live_cluster ? var.cluster_node_count : 3
    kops_state_store                     = data.terraform_remote_state.global.outputs.cloud_platform_kops_state
    oidc_issuer_url                      = local.oidc_issuer_url
    oidc_client_id                       = auth0_client.kubernetes.client_id
    network_cidr_block                   = data.aws_vpc.selected.cidr_block
    network_id                           = data.aws_vpc.selected.id
    internal_subnets_id_a                = sort(data.aws_subnet_ids.private.ids)[0]
    internal_subnets_id_b                = sort(data.aws_subnet_ids.private.ids)[1]
    internal_subnets_id_c                = sort(data.aws_subnet_ids.private.ids)[2]
    external_subnets_id_a                = sort(data.aws_subnet_ids.public.ids)[0]
    external_subnets_id_b                = sort(data.aws_subnet_ids.public.ids)[1]
    external_subnets_id_c                = sort(data.aws_subnet_ids.public.ids)[2]
    authorized_keys_manager_systemd_unit = indent(6, module.bastion.authorized_keys_manager)
    kms_key                              = aws_kms_key.kms.arn
    worker_node_machine_type             = var.worker_node_machine_type
    master_node_machine_type             = var.master_node_machine_type
  }
}

