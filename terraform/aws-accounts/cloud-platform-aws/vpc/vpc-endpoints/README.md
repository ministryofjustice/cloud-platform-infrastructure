# Cloud Platform – S3 Gateway Endpoints

This code configures the Cloud Platform VPCs to use S3 Gateway Endpoints, ensuring traffic between workloads and Amazon S3 stays within the AWS network. This improves security, resilience, and reduces NAT Gateway egress costs.

## How S3 Gateway Endpoints work on the Cloud Platform

S3 Gateway Endpoints allow private subnets to reach S3 without public internet routing.
This is done by creating a VPC endpoint of type Gateway and associating it with the private route tables.

The Cloud Platform VPC already has private route tables.

## The S3 Gateway Endpoint resource uses this value to determine routing:

```module "aws_vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.0.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = local.private_route_table_ids
      tags            = { Name = "${terraform.workspace}-s3-vpce" }
    }
  }
}
```

No manual route table updates are required — the module handles this automatically.

## Expected Behaviour

- S3 traffic from workloads in private subnets routes internally via the Gateway Endpoint

- No disruption to existing S3 access

- No action required by service teams

## Validation

You can validate endpoint functionality by:

- Running a connectivity test from a pod with IRSA permissions to an s3 bucket

- Checking that NAT Gateway egress metrics do not increase during the test

## Notes

Applies to Cloud Platform VPCs

Reusable for any new VPCs added in future

Improves network security posture by avoiding public internet routing
