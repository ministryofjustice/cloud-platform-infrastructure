locals {
  flattened_tgw_routes = merge([
    for table_name, routes in local.tgw_route_table_routes :
    {
      for cidr, attachment_id in routes :
      "${table_name}:${cidr}" => {
        route_table_name = table_name
        destination_cidr = cidr
        attachment_id    = attachment_id
      }
    }
  ]...)
  tgw_route_table_names = toset(["external", "inspection", "internal"])
  tgw_route_table_routes = {
    external = {
      "172.20.0.0/16" = module.cloud-platform-transit-gateway.ec2_transit_gateway_vpc_attachment["inspection"].id,
      "10.195.0.0/16" = module.cloud-platform-transit-gateway.ec2_transit_gateway_vpc_attachment["inspection"].id,
    },
    /* This will require established peering with LAA ECP and MOJ TGW for full routing assignments
    inspection = {
      "10.0.0.0/8" = data.aws_ec2_transit_gateway_peering_attachment.moj-tgw.id,
      "172.12.0.0/12" = data.aws_ec2_transit_gateway_peering_attachment.moj-tgw.id,
      "192.168.0.0/16" = data.aws_ec2_transit_gateway_peering_attachment.moj-tgw.id,
      "10.205.4.0/22" = data.aws_ec2_transit_gateway_peering_attachment.laa-ecp-tgw.id
    },
    */
    internal = {
      "10.0.0.0/8"     = module.cloud-platform-transit-gateway.ec2_transit_gateway_vpc_attachment["inspection"].id,
      "172.16.0.0/12"  = module.cloud-platform-transit-gateway.ec2_transit_gateway_vpc_attachment["inspection"].id,
      "192.168.0.0/16" = module.cloud-platform-transit-gateway.ec2_transit_gateway_vpc_attachment["inspection"].id,
    }
  }
  vpc_attachments = {
    inspection = {
      appliance_mode_support                          = true
      route_table                                     = "inspection"
      subnet_ids                                      = toset([for subnet in data.aws_subnet.inspection_vpc : subnet.id])
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      vpc_id                                          = data.aws_vpc.selected["inspection-vpc"].id
      tags                                            = { Name = "inspection-tgw-attachment" }
    }
    live_1 = {
      route_table                                     = "internal"
      security_group_referencing_support              = true
      subnet_ids                                      = toset([for subnet in data.aws_subnet.live_1 : subnet.id])
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      vpc_id                                          = data.aws_vpc.selected["live-1"].id
      tags                                            = { Name = "live-1-tgw-attachment" }
    }
    live_2 = {
      route_table                                     = "internal"
      security_group_referencing_support              = true
      subnet_ids                                      = toset([for subnet in data.aws_subnet.live_2 : subnet.id])
      transit_gateway_default_route_table_association = false
      transit_gateway_default_route_table_propagation = false
      vpc_id                                          = data.aws_vpc.selected["live-2"].id
      tags                                            = { Name = "live-2-tgw-attachment" }
    }
  }
  vpc_attachments_without_inspection = toset([for key in keys(local.vpc_attachments) : tostring(key) if key != "inspection"])
}

module "cloud-platform-transit-gateway" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "2.13.0"

  name        = "cloud-platform-transit-gateway"
  description = "Transit Gateway connecting the MOJ Cloud Platform with internal AWS and on-premise environments."

  create_tgw_routes                      = false
  enable_default_route_table_association = false
  enable_default_route_table_propagation = false
  share_tgw                              = false
  vpc_attachments                        = local.vpc_attachments
}

/* aws_ec2_transit_gateway_route_table doesn't appear to consume default_tags supplied by the provider.
 Possibly related to https://github.com/hashicorp/terraform-provider-aws/issues/37297 */
resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each           = local.tgw_route_table_names
  transit_gateway_id = module.cloud-platform-transit-gateway.ec2_transit_gateway_id
  tags = {
    Name          = each.key
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

/* Ensure all attached VPCs propagate their routes into the inspection route table */
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection" {
  for_each                       = local.vpc_attachments_without_inspection
  transit_gateway_attachment_id  = module.cloud-platform-transit-gateway.ec2_transit_gateway_vpc_attachment[each.key].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this["inspection"].id
}

resource "aws_ec2_transit_gateway_route" "this" {
  for_each                       = local.flattened_tgw_routes
  destination_cidr_block         = each.value.destination_cidr
  transit_gateway_attachment_id  = each.value.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id
}
