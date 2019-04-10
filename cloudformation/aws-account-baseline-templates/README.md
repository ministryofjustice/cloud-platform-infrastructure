# AWS Account Baseline Templates
The lowest acceptable common denominator of security-related promises, capabilities and configurations of MOJ AWS accounts.

## Background
As an organization expands its use of AWS services, there is often a conversation about the need to create multiple AWS accounts to ensure separation of business processes or for security, compliance, and billing. We tend to use separate AWS accounts for each business unit so that it can meet the different needs of the organization. Although creating multiple accounts has simplified operational issues and provided benefits like security and resource isolation, a smaller blast radius, and simplified billing, it results in widely varying security posture across the accounts and there is the need to align all of these accounts to a baseline secure standard. 

The list of [baseline-controls] (https://docs.google.com/document/d/1TWdeTmiMDbjcEnOzEXizr6254fGsZ6Wc77tKygCi4Ng/edit#heading=h.9j1uay34xjpw) for AWS accounts are -

* [Guardduty](#Guardduty)
* [Cloudtrail](#Cloudtrail)
* [Config Service](#Config)
* [Tagging](#Tagging)
* [Regions](#Regions)
* [Identity and Access Management](#Identity-and-Access-Management)
* [S3 Encryption](#S3-Encryption)
* [Leaky Bucket Problem](#Leaky-Bucket-Problem)
* [SecurityHub](#SecurityHub)

This section provides the definition of baseline controls and list of templates that cover the baseline and governance guardrails that can be deployed to new accounts.

## GuardDuty
We want to leverage AWS’ commodity IDS solution to detect/protect from malicious or unauthorized behavior
As baseline, we would want GuardDuty is enabled on all accounts, in all regions, all of the time

Please refer the Help Document for further details - cloud-platform-infrastructure/terraform/global-resources/docs/GuardDutyREADME.md 

NOTE -
It is a terraform template

```
git clone git@github.com:ministryofjustice/cloud-platform-infrastructure.git
cd cloud-platform-infrastructure/terraform/global-resources/
# guardduty.tf defines the Guardduty implementation
```

## [CloudTrail](aws-config-cloudtrail-logging/README.md)
AWS CloudTrail is a service that enables governance, compliance, operational auditing, and risk auditing of the AWS account. With CloudTrail, we can log, continuously monitor, and retain account activity related to actions across the AWS infrastructure. CloudTrail provides event history of the AWS account activity, including actions taken through the AWS Management Console, AWS SDKs, command line tools, and other AWS services. This event history simplifies security analysis, resource change tracking, and troubleshooting.

## [Config](aws-config-cloudtrail-logging/README.md)
AWS Config is a service that enables to assess, audit, and evaluate the configurations of the AWS resources. Config continuously monitors and records the AWS resource configurations and allows to automate the evaluation of recorded configurations against desired configurations. With Config, we can review changes in configurations and relationships between AWS resources, dive into detailed resource configuration histories, and determine the overall compliance against the configurations specified in the internal guidelines. This service enables to simplify compliance auditing, security analysis, change management, and operational troubleshooting.

## [Tagging](https://aws.amazon.com/answers/account-management/aws-tagging-strategies/)
Amazon Web Services (AWS) allows to assign metadata to the AWS resources in the form of tags. Each tag is a simple label consisting of a customer-defined key and an optional value that can make it easier to manage, search for, and filter resources. Although there are no inherent types of tags, it enables to categorize resources by purpose, owner, environment, or other criteria. This section describes commonly used tagging categories and strategies to help implement a consistent and effective tagging strategy.

## [Regions](aws-iam-user-roles-groups/README.md)
We do not wish to use non-EU AWS regions for strategic compliance and performance reasons. More on example Organisational [Service Control Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_example-scps.html)

## [Identity and Access Management](aws-iam-user-roles-groups/README.md)
AWS Identity and Access Management (IAM) enables to manage access to AWS services and resources securely. Using IAM, we can create and manage AWS users and groups, and use permissions to allow and deny their access to AWS resources. 

Note -
[Inactive User Check](aws-iam-suspend-inactive-users/README.md)
To increase the security of the AWS account, we need to remove IAM user credentials (passwords and access keys) that are not needed. This section provides template to deploy lambda functions to monitor and remove inactive users and credentials.

## S3 Encryption
Amazon S3 default encryption provides a way to set the default encryption behavior for an S3 bucket. Default encryption can be set on a bucket so that all objects are encrypted when they are stored in the bucket. The objects are encrypted using server-side encryption with either Amazon S3-managed keys (SSE-S3) or AWS KMS-managed keys (SSE-KMS).

* [Monitor the encryption status of S3 buckets using Config Rule](aws-config-cloudtrail-logging/README.md)
* [Apply the Default Encryption for S3 buckets](aws-s3-enable-encryption-block-public-access/README.md)

## [Leaky Bucket Problem](aws-s3-object-auto-remediation/README.md)
If the number of objects and users in the AWS account is large, ensuring that we have attached correctly configured ACLs to the objects can be a challenge. This section provides a solution that uses Amazon CloudWatch Events to detect changes in S3 object permissions in near real time and helps ensure that the objects remain private by making automatic API calls when necessary.

## [SecurityHub](https://aws.amazon.com/security-hub/)
AWS Security Hub aggregates, organizes, and prioritizes the security alerts, or findings, from multiple AWS services, such as Amazon GuardDuty, Amazon Inspector, and Amazon Macie, as well as from AWS Partner solutions. The findings are visually summarized on integrated dashboards with actionable graphs and tables. We can also continuously monitor the environment using automated compliance checks based on the AWS best practices and industry standards


Reference -
* https://docs.google.com/document/d/1TWdeTmiMDbjcEnOzEXizr6254fGsZ6Wc77tKygCi4Ng/edit#heading=h.9j1uay34xjpw
* https://aws.amazon.com/answers/security/aws-secure-account-setup/
* https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html
