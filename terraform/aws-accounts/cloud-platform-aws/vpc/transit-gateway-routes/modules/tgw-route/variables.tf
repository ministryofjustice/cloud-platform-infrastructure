variable "route_tables" {
  type        = list(string)
  description = "List of route tables to add route to."
}

variable "destination_cidr_block" {
  type        = string
  description = "Destination CIDR block for route."
}

variable "transit_gateway_id" {
  type        = string
  description = "TGW ID to route traffic to."
}
