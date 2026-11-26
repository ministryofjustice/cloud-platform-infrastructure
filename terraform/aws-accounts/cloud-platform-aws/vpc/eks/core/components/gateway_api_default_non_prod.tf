resource "aws_eip" "gateway_default_non_prod" {
  for_each = terraform.workspace == "live" ? toset(["a", "b", "c"]) : toset([])
  domain   = "vpc"

  tags = merge(local.default_tags, {
    Name = "${terraform.workspace}-envoy-default-non-prod-eu-west-2${each.key}"
  })
}

module "gateway_api_default_non_prod" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-gateway-api?ref=1.1.1"
  count  = terraform.workspace == "live" ? 1 : 0

  gateway_name        = "default-non-prod"
  cluster_base_domain = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  lb_name_prefix      = terraform.workspace
  enable_coraza       = true
  eip_allocation_ids  = [for eip in aws_eip.gateway_default_non_prod : eip.allocation_id]

  enable_anti_affinity = terraform.workspace == "live" ? true : false
  envoy_proxy_replicas = terraform.workspace == "live" ? 3 : 2
  memory_requests      = lookup(local.live_workspace, terraform.workspace, false) ? "1Gi" : "512Mi"
  memory_limits        = lookup(local.live_workspace, terraform.workspace, false) ? "2Gi" : "1Gi"

  default_tags = local.default_tags

  depends_on = [module.gateway_api_default]
}

resource "aws_shield_protection" "gateway_default_non_prod" {
  for_each = aws_eip.gateway_default_non_prod

  name = "${terraform.workspace}-envoy-default-non-prod-eu-west-2${each.key}"
  resource_arn = format(
    "arn:%s:ec2:%s:%s:eip-allocation/%s",
    data.aws_partition.gateway_shield.partition,
    data.aws_region.gateway_shield.name,
    data.aws_caller_identity.gateway_shield.account_id,
    each.value.id
  )

  tags = local.default_tags
}