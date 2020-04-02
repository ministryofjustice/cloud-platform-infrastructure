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
terraform init
terraform workspace select/new <clusterName>
terraform apply
```