# Cloud Platform Account - Terraform

This README will detail the purpose of the Cloud Platform Account layer in Terraform.

## Contents

- [Cloudtrail](#cloudtrail)
- [DLM](#dlm)
- [When do I use this?](#when-do-I-use-this)
- [How do I run this?](#terraform-modules)

## What it contains?

### CloudTrail

The `cloudtrail.tf` in this directory will create a cloudtrail and a bucket in your specified AWS account. Please note you can only run this once per account as there will be a name clash.

### DLM - Backup etcd Persistent Volumes

Created to backup etcd persistent volumes within an AWS account.

### SQS - Contains resources for management of VPC flowlog, cloudtrail and R53 Resolver log shipping to XSIAM

#### Bucket Names

| AWS Account                | Bucket Name                                            |
| -------------------------- | ------------------------------------------------------ |
| moj-platforms-intergration | cloud-platform-intergration-etcdbackup-terraform-state |
| cloud-platform-aws         | cloud-platform-aws-etcdbackup-terraform-state          |

#### Terraform Execution

The following will be created:

| Action                                    | Name                       |
| ----------------------------------------- | -------------------------- |
| aws_iam_role.dlm_lifecycle_role           | dlm-lifecycle-role         |
| aws_iam_policy.dlm_policy                 | dlm-policy                 |
| aws_iam_role_policy_attachment.dlm_attach | dlm_attach                 |
| aws_dlm_lifecycle_policy.etcd_backup      | etcd data lifecycle policy |

#### Etcd Data Lifecycle Policy Values

| Name              | Value                       |
| ----------------- | --------------------------- |
| Schedule name     | Daily 2 week etcd snapshots |
| interval          | 24                          |
| interval_unit     | HOURS                       |
| times             | 06:00                       |
| retain_rule count | 14                          |
| tags_to_add       | SnapshotCreator:DLM         |
| target_tags       | k8s.io/role/master:1        |

#### Restore Process

In case the Kubernetes cluster fails in a way that too many master nodes can't access their etcd volumes it is impossible to get a etcd quorum.

Kubernetes uses protokube to identify the right volumes for etcd. Therefore it is important to tag the EBS volumes with the correct tags after restoring them from a EBS snapshot.

protokube will look for the following tags:

`KubernetesCluster` containing the cluster name (e.g. `k8s.mycompany.tld`)
`Name` containing the volume name (e.g. `eu-central-1a.etcd-main.k8s.mycompany.tld`)
`k8s.io/etcd/main` containing the availability zone of the volume (e.g. `eu-central-1a/eu-central-1a`)
`k8s.io/role/master` with the value `1`

Go to EC2 > EBS > Snapshots. Find the appopiate backups, all tags including name tag will be present for each PV backed up. Once selected, click Actions > Create Volume. Click [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-restoring-volume.html) for offical AWS documentation.

After fully restoring the volume ensure that the old volume is no longer there, or you've removed the tags from the old volume. After restarting the master node Kubernetes should pick up the new volume and start running again.

## When do I use this?

The idea of this directory is to collect all terraform that runs at account level. For example, if you provision a brand new account to be used as part of the Cloud Platform, you should run this terraform.

## How do I use this?

```bash
terraform init
terraform workspace select/new <AWSaccountName>
terraform apply
```
