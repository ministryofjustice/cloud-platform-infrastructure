# Cloud Platform - Starter pack

This README describes how to create and deploy starter pack apps to a kubernetes cluster. 

## Contents

  - [Requirements](#Requirements)
  - 


## Requirements

- Terraform >= 12

## `main.tf` 

Within `main.tf` you will have the resource to create namespace and module to deploy the apps into your kubernetes cluster. For more details of how to create multiple copies of the deployment in different namespace refer [cloud-platform-terraform-starter-pack](https://github.com/ministryofjustice/cloud-platform-terraform-starter-pack)

## How to use this module

```bash

export CLUSTER_NAME = <cluster name>

terraform init \
  -backend-config="bucket=cloud-platform-terraform-state" \
  -backend-config="key=cloud-platform-starter-pack/${CLUSTER_NAME}/terraform.tfstate" \
  -backend-config="region=eu-west-1"

terraform workspace select/new <clusterName>

terraform apply
```