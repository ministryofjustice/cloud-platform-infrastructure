## Fixed public IPs for the default Gateway NLB.
# Kept outside the module so they survive the Gateway/NLB being re-created.
# One per public subnet/AZ the NLB uses; only applied when the NLB is created.
resource "aws_eip" "gateway_default" {
  for_each = toset(["a", "b", "c"])
  domain   = "vpc"

  tags = merge(local.default_tags, {
    Name = "${terraform.workspace}-envoy-default-eu-west-2${each.key}"
  })
}


module "gateway_api_default" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-gateway-api?ref=1.1.0"

  gateway_name        = "default"
  cluster_base_domain = data.terraform_remote_state.cluster.outputs.cluster_domain_name
  is_live_cluster     = lookup(local.prod_workspace, terraform.workspace, false)
  live1_cert_dns_name = lookup(local.live1_cert_dns_name, terraform.workspace, "")
  lb_name_prefix      = terraform.workspace
  enable_coraza       = true
  eip_allocation_ids  = [for eip in aws_eip.gateway_default : eip.allocation_id]

  enable_anti_affinity = terraform.workspace == "live" ? true : false

  envoy_proxy_replicas = terraform.workspace == "live" ? 3 : 2
  memory_requests      = lookup(local.live_workspace, terraform.workspace, false) ? "1Gi" : "512Mi"
  memory_limits        = lookup(local.live_workspace, terraform.workspace, false) ? "2Gi" : "1Gi"

  default_tags = local.default_tags
}

# Shield advanced protection for the Gateway NLB EIPs

data "aws_caller_identity" "gateway_shield" {}

data "aws_region" "gateway_shield" {}

data "aws_partition" "gateway_shield" {}

resource "aws_shield_protection" "gateway_default" {
  for_each = aws_eip.gateway_default

  name = "${terraform.workspace}-envoy-default-eu-west-2${each.key}"
  resource_arn = format(
    "arn:%s:ec2:%s:%s:eip-allocation/%s",
    data.aws_partition.gateway_shield.partition,
    data.aws_region.gateway_shield.name,
    data.aws_caller_identity.gateway_shield.account_id,
    each.value.id
  )

  tags = local.default_tags
}