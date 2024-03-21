# Cloud Platform Infrastructure - Terraform

This `README` will serve as a brief outline of the `cloud-platform-infrastructure/terraform` directory and its structure. Each directory will contain a README outlining its own function and design.

```
├── README.md
├── aws-accounts         # resources split up by AWS account
├── global-resources     # common resources for all clusters across a multitude of AWS accounts
├── cross-account-IAM    # cross-account IAM - will be deleted soon - see https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/migrate-to-live.html#step-3-migrate-your-namespace-environment-to-quot-live-quot
└── modules
```

The nesting of the terraform folders reflects the **dependencies** between them. For example when you are provisioning a new cluster, the terraform must be [applied in this order](https://runbooks.cloud-platform.service.justice.gov.uk/eks-cluster.html):

```
aws-accounts/cloud-platform-aws/vpc
aws-accounts/cloud-platform-aws/vpc/eks
aws-accounts/cloud-platform-aws/vpc/eks/core
aws-accounts/cloud-platform-aws/vpc/eks/core/components
```

## Deployment

There is Continuous Deployment for this terraform: [cloud-platform-infrastructure Concourse pipeline](https://concourse.cloud-platform.service.justice.gov.uk/teams/main/pipelines/cloud-platform-infrastructure)

Terraform folders can also be applied manually using this general formula:

```terraform
terraform init
terraform workspace select <clusterName>  # this line is not needed for global-resources
terraform apply
```

Each folder's README should have a "How do I use this?" section with the precise commands.
