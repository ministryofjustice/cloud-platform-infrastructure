 Cloud Platform Transit Gateway

This Terraform module configures an AWS Transit Gateway to route traffic between the Cloud Platform and internal MOJ environments.

## Overview

The configuration performs the following tasks:

- Provisions the Transit Gateway using the `terraform-aws-modules/transit-gateway` module.
- Creates route tables for the Transit Gateway using resource declarations and local values
- Uses the data sources to retrieve VPC and subnet details for attachable VPCs
- Hold configuration for attachable VPCs as a local value

## Components

- **Data Sources**:
  - Identifies the attachable VPCs and relevant subnets for Transit Gateway endpoints.
- **Local Values**:
  - Structures VPC attachment configuration.
  - Defines Transit Gateway route table names
- **Transit Gateway**:
  - Deployed without default route table association or propagation.
  - VPC attachments are explicitly defined for controlled routing.

## Notes

- No automatic attachment is enabled; VPCs must be defined in `local.vpc_attachments`.
- No automatic route propagation is enabled; routing must be handled separately.