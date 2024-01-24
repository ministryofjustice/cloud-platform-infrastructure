# Cloud Platform - Live

This code defines the Cloud Platform configuration to use the Transit Gateway.

## Requirements

To run the terraform code, you must have on your local machine :

- `moj-transit` AWS Profile
- `moj-cp` AWS Profile
- `terraform v1.2.5`

## How to add a new route on live-1 VPC

For two VPCs attached to a Transit Gateway to be connected, two new routes need to be connected :

`VPC A -> route to B -> TGW <- route to A <- VPC B`

The Cloud Platform team can only create one of this route (from CP to VPC B)

This repo has access to the Cloud Platform terraform state (aws-accounts/cloud-platform-aws/vpc/live-1).

it is fetching the route tables of the live-1 VPC, and storing it in a local variable:

```
locals {
  route_tables = data.terraform_remote_state.cluster-network.outputs.private_route_tables
}
```

This var is then used in the `aws_route` resources.  
For each entry in `local.route_table`, create a new route.

```
resource "aws_route" "example" {
  count = length(local.route_tables)
  route_table_id            = local.route_tables[count.index]
  destination_cidr_block    = "10.x.x.x/16"
  transit_gateway_id = "tgw-05acb84d26b244813"
}
```

Note: live-1 vpc is shared VPC, for cloud platform "live" and "manager" K8's clusters.
