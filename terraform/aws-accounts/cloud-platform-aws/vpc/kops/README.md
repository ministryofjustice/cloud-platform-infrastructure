# Cloud Platform - Terraform

This README will detail the purpose of the Cloud Platform layer in Terraform. The Cloud Platform in this context refers to the Kubernetes platform built by the MoJ Cloud Platform team. All Terraform in this directory will create cluster specific infrastructure. 

## Contents
  - [Bastion](#bastion)
  - [Kops](#kops)
  - [When do I use this?](#when-do-I-use-this)
  - [How do I run this?](#terraform-modules)

## What it contains?
### Bastion
The `bastion.tf` in this directory will create you all relevant components for a bastion host. You can use this host to ssh onto your worker nodes. 

### Kops
The `kops.tf` will create a kops manifest in `cloud-platform-infrastructure/kops`. This manifest will all you to create your master and worker nodes along with relevant components to give you a working Kubernetes cluster. Run this with `kops create -f <file>` to create your cluster. 

## When do I use this?
The idea of this directory is to collect all terraform that runs at cluster level. For example, if you wanted to create a new cluster for live or test, you would use this directory. 

## How do I use this?
```bash
terraform init
terraform workspace select/new <clusterName>
terraform apply
```
