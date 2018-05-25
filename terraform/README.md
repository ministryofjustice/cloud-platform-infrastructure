# Kubernetes Investigations Terraform code

This Readme includes the Terraform code part for the Kubernetes investigations repository.
The following directory is structured into:

```
├── README.md
├── cloud-platform
├── global-resources
└── modules
```
## Cloud Platform
The cloud-platform directory is were the cluster specific code lives and relies on Terraform workspaces as the starting point.

## Global Resources
The global-resources directory contains Terraform code to build the common resources for all clusters.
Within Global Resources you can find:

### ecr_credentials.tf

This Terraform file uses the following Terraform module which creates ECR credentials and repository on AWS.
This Module is used to create the user, ECR repository and credentials for our example app. The team name is `webops` and the repository name is `cloud-platform-reference-app` and these are the parameters used by the module in this case

* [AWS ECR Cloud Platform Terraform module](https://github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials)

### How to use the Module

#### Context

This module can be used by cloud platforms to create an ECR repository, credentials, and a user for other teams upon request. An ERC repository and credentials are required by any team to build and application on AWS. They would need to upload the image into ECR to use it within AWS.

The way to use this module, similarly than the ecr_credentials.tf, a new Terraform TF file needs to be created with:

```hcl
module "team_ECR_credentials" {
  source = "github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials?ref=master"

  repository_name = "team-repository"
  team_name = "the-team"
}
```

Where the `repository_name` and `team_name` variables would have to be replaced with the team specifics, along with the module name.

To run this example you need to execute:

```bash
$ Terraform init
$ Terraform plan
$ Terraform apply
```
In the same directory where the newly created Terraform file lives.

**Note that this example may create resources which can cost money. Run `Terraform destroy` when you don't need these resources.**

The user_name ,secret_access_key and repository_arn outputs will need to be distributed to the Team after this code is run.

## Modules
The modules directory contains Terraform modules within this repository. These modules will need to be migrated to one git repository per module, the same way the AWS ECR module was built.

