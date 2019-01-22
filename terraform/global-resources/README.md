# global-resources

These are resources that are global in nature and therefore there are no workspaces in this terraform state.

---
**NOTE**

Since resources in multiple accounts are managed here, multiple AWS providers are defined.
You can see the list of providers in [main.tf](main.tf#L10-L29), as well as the names of the AWS profiles that must be configured for this to run properly.

---
# global-resources

These are resources that are global in nature and therefore there are no workspaces in this terraform state.

---
**NOTE**

Since resources in multiple accounts are managed here, multiple AWS providers are defined.
You can see the list of providers in [guardduty.tf](guardduty.tf#L10-L29), as well as the names of the AWS profiles that must be configured for this to run properly.

---

# GuardDuty utilising Terraform
  
## Introduction

Amazon GuardDuty is a continuous security monitoring service that analyzes and processes the following data sources:

* VPC Flow Logs
* AWS CloudTrail event logs
* DNS logs.

It uses threat intelligence feeds, such as:

* lists of malicious IPs
* lists of malicious domains
* machine learning to identify unexpected and potentially unauthorized and malicious activity within your AWS environment. This can include issues like escalations of privileges, uses of exposed credentials, or communication with malicious IPs, URLs, or domains. For example, GuardDuty can detect compromised EC2 instances serving malware or mining bitcoin.
It also monitors AWS account access behavior for signs of compromise, such as unauthorized infrastructure deployments, like instances deployed in a region that has never been used, or unusual API calls, like a password policy change to reduce password strength.

GuardDuty informs you of the status of your AWS environment by producing security findings that you can be viewed in the GuardDuty console or through Amazon CloudWatch events.

Our setup at the moment is a very basic set up of GuardDuty in a single AWS Region. There is at present one master account, [moj-cloud-platform](https://moj-cloud-platform-test-2.eu.auth0.com/samlp/WAgw4FygIHs1Vny6whAjfnem6BiUr4qv) controlling several member accounts.

Any findings in GuardDuty are sent to Cloudwatch event rules that then integrate with AWS SNS (Simple Notification Service) topics and subscriptions. These are alerted to Pagerduty (presently 'in office hours') and then onto slack channels (at the moment #lower-priority-alarms)

Please see [AWS GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html) regarding setting up AWS GuardDuty.

Also see here [Aws Cloudwatch Frequently Asked Questions](https://aws.amazon.com/guardduty/faqs/ where most general information regarding this service can be found)

Consideration will have to be given as to whether GuardDuty is set up here in [moj-cloud-platform](https://moj-cloud-platform-test-2.eu.auth0.com/samlp/WAgw4FygIHs1Vny6whAjfnem6BiUr4qv) or whether it should be in the digital AWS route account. You will then be able to set up control of AWS subaccounts from here.

Please also see [terraform aws GuardDuty detector ](https://www.terraform.io/docs/providers/aws/r/guardduty_detector.html) regarding setting up the config (here) for terraform GuardDuty detector

## Table of contents
  - [1 Prerequisite files](#1-prerequisite-files)
  - [2 Adding a new member account](#2-adding-a-new-member-account)
  - [3 Applying the terraform changes](#3-applying-the-terraform-changes)
  - [4 Pagerduty to Slack integration](#4-pagerduty-to-slack-integration)

### 1 Prerequisite files

  - [Main Configuration File](#main-configuration-file) (guardduty.tf)
  - [Terraform Variables File](#terraform-variables-file) (terraform.tfvars)
  - [AWS Cloudwatch Event Rules File](#aws-cloudwatch-event-rules-file) (event-pattern.json)
  - [Trusted ip List File](#trusted-ip-list-file)  (iplist.txt)
  - [Variables Initialisation File](#variables-initialisation-file) (variables.tf)


#### Main Configuration File

'guardduty.tf contains code for the following config:

* Enabling and turning GuardDuty on for the master account.
* Enabling and turning GuardDuty on for the member account.
* Setting up the S3 bucket and then adding trusted IP ranges etc to its contents.
* On the master account - setting up the iam group with the appropriate iam policies, allowing the setup, configuration and use of GuardDuty. Also allowing full access to the contents of the security bucket.
* On the master account - Adding chosen iam users to the iam groups so that they have admin permissions to set up and use GuardDuty..
* On the master account -Setting up AWS Cloudwatch Event rules to integrate with 'AWS GuardDuty Findings' and config to alert to the relevant AWS sns topic (and thence onto pagerduty)
.Also to set up an event pattern (json file).
* On the master account Setting up the relevant GuardDuty AWS SNS (Simple Notification Service) topic and subscription.

#### Terraform Variables File

'terraform.tfvars' contains code for the following config variables:

* aws_region
* aws_profile for the master and member accounts (set locally in ~/.aws/credentials). This is set up using format "moj-[account] (see terraform.tfvars file)
* aws_account_id (the id for the master and member aws accounts)
* integration_key (the Amazon-GuardDuty service integration key configured in pagerduty to integrate with AWS Guardduty)
* users (admin aws iam  users)
* topic_arn = "arn:aws:sns:eu-west-1:[aws-account-id]:GuardDuty-notifications" (this is how it will be configured as an aws sns (simple notification service) topic
* endpoint  = ``` https://events.pagerduty.com/integration/[pagerduty to AWS Guardduty integraion_key]/enqueue ``` this is required by the sns subscription endpoint configuration)
* member_email (the email to which the initial invitation email(s) should be sent {from the master account} when setting up GuardDuty on the member account - this must match email used to set up the root account)
#### AWS Cloudwatch Event Rules File

'event-pattern.json'

* A json object that is used by 'AWS Cloudwatch Event Rules' to select 'AWS Guardduty Events' (findings) and route them to the AWS sns targets


#### Trusted ip List File

'iplist.txt'

* A trusted ip list. GuardDuty does not generate findings for IP addresses that are included in this trusted IP list/s
At this point in time terraform is unable to update this list by 'terraform apply'. The list has to be manually deleted in the AWS dashboard >  Guardduty > Lists > Trusted IP Lists. Then you can run the 'terraform apply.

#### Variables Initialisation File

'variables.tf'

* Used to set up the terraform variables and defaults required by terraform 'guardduty.tf'

### 2 Adding a new member account

* guardduty.tf add the following (incrementing the member no as required):

```
# -----------------------------------------------------------
# membership7 account provider
# -----------------------------------------------------------

provider "aws.member7" {
  region  = "${var.aws_region}"
  profile = "${var.aws_member7_profile}"
}

# -----------------------------------------------------------
# membership7 account GuardDuty detector
# -----------------------------------------------------------

resource "aws_guardduty_detector" "member7" {
  provider = "aws.member7"

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# -----------------------------------------------------------
# membership7 account GuardDuty member
# -----------------------------------------------------------

resource "aws_guardduty_member" "member7" {
  account_id         = "${aws_guardduty_detector.member7.account_id}"
  detector_id        = "${aws_guardduty_detector.master.id}"
  email              = "${var.member7_email}"
  invite             = true
  invitation_message = "please accept guardduty invitation"
}
```

* variable.tf add the following (incrementing the memmber no as required):

```
variable "aws_member7_account_id" {}
variable "aws_member7_profile" {}
variable "member7_email" {}
```

* terraform.tfvars add the following (incrementing the member no as required):

```
aws_member7_profile = "moj-[account name]"
aws_member7_account_id = "[aws account id]"
member7_email = "[root email address at time of account creation]"
```

* In AWS member account Dashboard go to GuardDuty link > Accounts > Accept the invite
This will add GuardDuty in the member account. Fidings will now also appear in the GuardDuty master accounty.

### 3 Applying the terraform changes

```
terraform init
terraform plan
terraform apply (answer 'yes' to actually update remote config)
```

### 4 Pagerduty to Slack integration

This is is also set up utilising terraform separately config here:

* https://github.com/ministryofjustice/cloudplatforms-terraform-ops/blob/master/main.tf
* https://github.com/ministryofjustice/cloudplatforms-terraform-ops/blob/master/services/amazon-guardduty-notifications/pagerduty.tf
