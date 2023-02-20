# Cloud Platform - Network Components

This README describes how to provision networking components required by a Kubernetes cluster.

## Contents

- [Requirements](#Requirements)

## Requirements

- Terraform >= 12
- Ensure you have `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` exported

## `main.tf`

Within `main.tf` we find the resources and modules required by the EKS/kOps clusters, initially it is just a VPC with subnets, NAT gateways, etc

## How to use this module

```bash
terraform init
terraform workspace select/new <clusterName>
terraform apply
```
