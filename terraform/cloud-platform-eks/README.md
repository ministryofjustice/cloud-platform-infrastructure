# Cloud Platform - EKS Cluster

This README describes the main infrastructure components required to deliver a production-ready EKS cluster. Terraform is used as a main tool to bootstrap the infrastructure layer and EKS clusters. This terraform code requires you already have a VPC provisioned. If no VPC is provided it'll look for a VPC named as your terraform workspace 

## Contents

  - [Requirements](#Requirements)
  - [Cluster Dependences](#cluster-dependences)
  - [EKS](#eks)
  - [How do I run this?](#terraform-modules)

## Requirements

- Terraform >= 12
- [aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm <= 2.14.3](https://github.com/helm/helm/releases/tag/v2.14.3) 
- Ensure you have `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` exported

## What it contains?

### Cluster Dependences (`main.tf`)

Within `main.tf` you'll find creation of:

- Auth0 registration
- Route53 hostzones that your cluster will use
- AWS Key pairs
- Bastion: It calls the bastion module which creates a bastion instance inside a VPC that will grant access to internal subnets to the members of the team. You can use this host to ssh onto your worker nodes.
- etc

### EKS (`eks.tf`)

`eks.tf` holds the EKS definition, it is being used the official EKS module. Inside this file you'll specify workers, IAM permissions, etc. 

**NOTE**: Default cluster size is **21** nodes and default worker node types are **r5.2xlarge**. If you are just playing around or testing a feature it doesn't make sense to have these specs, please change them.

## How do I use this?

```bash
terraform init
terraform workspace select/new <clusterName>
terraform apply -var-file="vars/$(terraform workspace show).tfvars"
```
