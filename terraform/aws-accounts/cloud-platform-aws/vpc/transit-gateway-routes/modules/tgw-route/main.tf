resource "aws_route" "this" {
  count                  = length(var.route_tables)
  route_table_id         = var.route_tables[count.index]
  destination_cidr_block = var.destination_cidr_block
  transit_gateway_id     = var.transit_gateway_id
}
