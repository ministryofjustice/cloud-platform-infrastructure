# Cloud Platform - EKS Cluster

This README describes the main infrastructure components required to deliver a production-ready EKS cluster. Terraform is used as a main tool to bootstrap the infrastructure layer and EKS clusters. This terraform code requires you already have a VPC provisioned (go to [`terraform/cloud-platform-network/` folder for more info](https://github.com/ministryofjustice/cloud-platform-infrastructure/tree/main/terraform/cloud-platform-network)). If no VPC is provided it'll look for a VPC named as your terraform workspace

**IMPORTANT:** All cluster's names **must be globally unique**, each of them (EKS or kOps, doesn't matter) creates a Route53 hostzone which is unique

## Contents

- [Requirements](#Requirements)
- [Cluster Dependences](#cluster-dependences)
- [EKS](#eks)
- [How do I run this?](#terraform-modules)

## Requirements

- Terraform >= 14
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

### EKS (`cluster.tf`)

`cluster.tf` holds the EKS definition, it is being used the official EKS module. Inside this file you'll specify workers, IAM permissions, etc.

**NOTE**: Default cluster size is **21** nodes and default worker node types are **r5.2xlarge**. If you are just playing around or testing a feature it doesn't make sense to have these specs, please change them.

## How do I use this?

```console
terraform init
terraform workspace select/new <clusterName>
```

Now it is time to apply changes:

```console
terraform apply -var="vpc_name=$VPC_NAME"
```

**NOTE**: Don't forget to set the `vpc_name` variable, if you want to increase the number of nodes and machine type use: `cluster_node_count` and `worker_node_machine_type`

## How to access the cluster

In order to access the cluster and generate your kubeconfig file you must use the AWS-CLI as follows:

```console
aws eks --region eu-west-2 update-kubeconfig --name mogaal-eks
```

More guidance on how to install components on EKS cluster and delete the cluster can be found in the [Cloud Platform Runbook](https://runbooks.cloud-platform.service.justice.gov.uk/eks-tools-cluster.html#provisioning-eks-clusters)
