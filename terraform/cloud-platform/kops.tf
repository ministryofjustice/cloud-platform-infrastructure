resource "local_file" "kops" {
  filename = "../../kops/${terraform.workspace}.yaml"

  content = templatefile("${path.module}/templates/kops.yaml.tpl", {
    cluster_domain_name                  = local.cluster_base_domain_name
    cluster_node_count                   = local.is_live_cluster ? var.cluster_node_count : 3
    kops_state_store                     = data.terraform_remote_state.global.outputs.cloud_platform_kops_state
    oidc_issuer_url                      = local.oidc_issuer_url
    oidc_client_id                       = auth0_client.kubernetes.client_id
    network_cidr_block                   = data.aws_vpc.selected.cidr_block
    network_id                           = data.aws_vpc.selected.id
    internal_subnets_id_a                = data.aws_subnet.private_a.id
    internal_subnets_id_b                = data.aws_subnet.private_b.id
    internal_subnets_id_c                = data.aws_subnet.private_c.id
    external_subnets_id_a                = data.aws_subnet.public_a.id
    external_subnets_id_b                = data.aws_subnet.public_b.id
    external_subnets_id_c                = data.aws_subnet.public_c.id
    authorized_keys_manager_systemd_unit = indent(6, module.bastion.authorized_keys_manager)
    kms_key                              = aws_kms_key.kms.arn
    worker_node_machine_type             = var.worker_node_machine_type
    master_node_machine_type             = var.master_node_machine_type
    enable_large_nodesgroup              = var.enable_large_nodesgroup
  })
}

resource "aws_kms_key" "kms" {
  description = "Creates KMS key for etcd volume encryption"
}

