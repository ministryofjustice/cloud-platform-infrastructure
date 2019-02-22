# Cloud Platform - Global Resources - Terraform

These are resources that are global in nature and therefore there are no workspaces in this terraform state. The idea of this directory is that it's run across multiple AWS accounts and services.

---
**NOTE**

Since resources in multiple accounts are managed here, multiple AWS providers are defined.
You can see the list of providers in [main.tf](main.tf#L10-L29), as well as the names of the AWS profiles that must be configured for this to run properly.

---

## Contents
- [Auth0](#auth0)
- [DNS](#dns)
- [Elasticsearch](#elasticsearch)
- [GuardDuty](https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/global-resources/docs/GuardDutyREADME.md)
- [S3](#s3)
- [Saml](#saml)

### Auth0
We use Auth0 to proxy applications and have multiple tennats that perform this. The `auth0.tf` file in this directory will configure the rules to allow the MoJ `WebOps` group admin control over the cluster. 

### DNS
Sets up the parent and child zones for our Route53 configuration. 

### Elasticsearch
Creates live and audit Elasticsearch clusters, currently hosted on the integration AWS account. 

### S3
Simply creates S3 buckets across multiple AWS accounts. 

### saml
Attempts to setup single-sign-on for AWS. This feature is not yet working. 