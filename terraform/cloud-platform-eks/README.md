# Cloud Platform - EKS Cluster

This README describes the main infrastructure components required to deliver a production-ready EKS cluster. Terraform is used as a main tool to bootstrap the infrastructure layer and EKS clusters. 

## Contents
  - [Bastion](#bastion)
  - [Cluster Dependences](#cluster-dependences)
  - [EKS](#eks)
  - [When do I use this?](#when-do-I-use-this)
  - [How do I run this?](#terraform-modules)


## What it contains?

### Bastion

The `bastion.tf` file calls the bastion module, which creates a bastion instance inside a VPC that will grant access to internal subnets to the members of the team. You can use this host to ssh onto your worker nodes. 

### Cluster Dependences

Within `main.tf` you'll find creation of:

- VPCs: internal and external subnets, nat gateways, vpcs, etc
- Route53 hostzones that your cluster will use
- AWS Key pairs
- etc

### EKS 

`eks.tf` holds the EKS definition, it is being used the official EKS module. Inside this file you'll specify workers, IAM permissions, etc. 

**NOTE**: Default cluster size is **21** nodes and default worker node types are **r5.2xlarge**. If you are just playing around or testing a feature it doesn't make sense to have these specs, please change them.

## When do I use this?

The idea of this directory is to collect all terraform that runs at cluster level. For example, if you wanted to create a new cluster for live or test, you would use this directory. 

## How do I use this?

```bash
terraform init
terraform workspace select/new <clusterName>
terraform apply -var-file="vars/stg.tfvars"
```