## Cloud Platform – VPC Endpoints

This code defines the configuration used to manage AWS VPC Endpoints across the Cloud Platform VPCs (e.g., live, live-2).
VPC Endpoints allow private communication between workloads running on the platform and supported AWS services, without sending traffic over the public internet.

## Purpose

VPC Endpoints improve:

- Security – traffic stays within the AWS network boundary

- Cost efficiency – avoids NAT Gateway egress charges for AWS service traffic

They form part of the Cloud Platform’s ongoing work to internalise AWS service communication and strengthen the platform’s network security posture.

## Types of Endpoints

AWS provides two kinds of VPC Endpoints:

Gateway Targeted in route tables; used for S3 and DynamoDB. S3, DynamoDB
Interface (PrivateLink) Exposes an Elastic Network Interface (ENI) with a private IP in subnets; used for most other services: ECR, CloudWatch, STS, KMS, Secrets Manager, SSM

Each Cloud Platform VPC can host both endpoint types depending on the workloads’ needs.

## Implementation Overview

VPC Endpoints are defined using the shared Terraform module:

```
module "aws_vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.0.0"

  vpc_id = module.vpc.vpc_id
  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = local.private_route_table_ids
    }
  }
}
```

Endpoint resources are created per-VPC using standard tagging conventions.

Private DNS is enabled for Interface endpoints, so service hostnames (e.g., sts.amazonaws.com) resolve to internal addresses.

Gateway endpoints automatically attach to private route tables.

No action is required from service teams.
