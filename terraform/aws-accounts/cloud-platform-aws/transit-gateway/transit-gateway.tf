locals {
  tgw_route_table_names = toset(["external", "inspection", "internal"])
  vpc_attachments = {
    inspection = {
      appliance_mode_support = true
      enable_default_route_table_association = false
      enable_default_route_table_propagation = false
      route_table                            = "inspection"
      subnet_ids                             = toset([for subnet in data.aws_subnet.inspection_vpc_intra : subnet.id])
      vpc_id                                 = data.aws_vpc.inspection_vpc.id
    }
  }
}

module "cloud-platform-transit-gateway" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "2.13.0"

  name        = "cloud-platform-transit-gateway"
  description = "Transit Gateway connecting the MOJ Cloud Platform with internal AWS and on-premise environments."

  create_tgw_routes = false
  share_tgw         = false
  vpc_attachments   = local.vpc_attachments
}

/* aws_ec2_transit_gateway_route_table doesn't appear to consume default_tags supplied by the provider.
 Possibly related to https://github.com/hashicorp/terraform-provider-aws/issues/37297 */
resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = local.tgw_route_table_names
  transit_gateway_id = module.cloud-platform-transit-gateway.ec2_transit_gateway_id
  tags = {
    business-unit = "Platforms"
    application   = "cloud-platform-aws/transit-gateway"
    is-production = "true"
    owner         = "Cloud Platform: platforms@digital.justice.gov.uk"
    source-code   = "github.com/ministryofjustice/cloud-platform-infrastructure"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each                       = local.vpc_attachments
  transit_gateway_attachment_id  = module.cloud-platform-transit-gateway.ec2_transit_gateway_vpc_attachment[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table].id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each                       = local.vpc_attachments
  transit_gateway_attachment_id  = module.cloud-platform-transit-gateway.ec2_transit_gateway_vpc_attachment[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table].id
}
