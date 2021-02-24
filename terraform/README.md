# Cloud Platform Infrastructure - Terraform


This `README` will serve as a brief outline of the `cloud-platform-infrastructure/terraform` directory and its structure. Each directory will contain a README outlining its own function and design.

```
├── README.md
├── cloud-platform-account
├── cloud-platform-components
├── cloud-platform-dr
├── cloud-platform
├── global-resources
└── modules
```
At present, there is no pipeline to apply changes to the Cloud Platform Infrastructure so this must be applied locally using:

```terraform
terraform init
terraform workspace select <clusterName>
terraform apply
```
## Cloud Platform Account
To be run at account level only. Contains (AWS) account level configuration such as `cloudtrail` and `dlm`.

## Cloud Platform Components
Contains a variety of applications to bootstrap a Kubernetes cluster into a "ready" state including `pod-security-policies`, `monitoring` and `kiam`.

## Cloud Platform
This directory will create you the outlines of a Kubernetes cluster, including a `kops.tf` to be used to create or modify a cluster. 

## Cloud Platform DR
To be used in a disaster recovery scenario, which restores resources and data.

## Global Resources
The global-resources directory contains Terraform code to build the common resources for all clusters across a multitude of AWS accounts.
