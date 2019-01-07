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

Our setup at the moment is a very basic set up of GuardDuty in a single AWS account/Region. In this case [moj-cloud-platform](https://moj-cloud-platform-test-2.eu.auth0.com/samlp/WAgw4FygIHs1Vny6whAjfnem6BiUr4qv). 

Any findings in GuardDuty are sent to Cloudwatch event rules that then integrate with AWS SNS (Simple Notification Service) topics and subscriptions. These are alerted to Pagerduty (presently 'in office hours') and then onto slack channels (at the moment #lower-priority-alarms)

Please see [AWS GuardDuty](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_settingup.html) regarding setting up AWS GuardDuty.

Also see here [Aws Cloudwatch Frequently Asked Questions](https://aws.amazon.com/guardduty/faqs/ where most general information regarding this service can be found)

Consideration will have to be given as to whether GuardDuty is set up here in [moj-cloud-platform](https://moj-cloud-platform-test-2.eu.auth0.com/samlp/WAgw4FygIHs1Vny6whAjfnem6BiUr4qv) or whether it should be in the digital AWS route account. You will then be able to set up control of AWS subaccounts from here, [laa security](https://github.com/ministryofjustice/laa-aws-infrastructure/tree/master/security) is one such example of this

Please also see [terraform aws GuardDuty detector ](https://www.terraform.io/docs/providers/aws/r/guardduty_detector.html) regarding setting up the config (here) for terraform GuardDuty detector

## Table of contents
  - [1 Prerequisite files](#1-prerequisite-files)
  - [2 Pagerduty to Slack integration](#2-pagerduty-to-slack-integration)
  - [3 Applying the terraform changes](#3-applying-the-terraform-changes)

### 1 Prerequisite files

  - [Main Configuration File](#main-configuration-file) (main.tf)
  - [Terraform Variables File](#terraform-variables-file) (terraform.tfvars)
  - [AWS Cloudwatch Event Rules File](#aws-cloudwatch-event-rules-file) (event-pattern.json)
  - [Trusted ip List File](#trusted-ip-list-file)  (iplist.txt)
  - [Variables Initialisation File](#variables-initialisation-file) (variables.tf) 


#### Main Configuration

'main.tf contains code for the following config:

* Enabling and turning GuardDuty on.
* Setting up the S3 bucket and then adding trusted IP ranges etc to its contents.
* Setting up the iam group with the appropriate iam policies, allowing the setup, configuration and use of GuardDuty. Also allowing full access to the contents of the security bucket.
* Adding chosen iam users to the iam groups so that they have admin permissions to set up and use GuardDuty..
* Setting up AWS Cloudwatch Event rules to integrate with 'AWS GuardDuty Findings' and config to alert to the relevant AWS sns topic (and thence onto pagerduty)
.Also to set up an event pattern (json file).
* Setting up the relevant GuardDuty AWS SNS (Simple Notification Service) topic and subscription.

#### Terraform Variables File

'terraform.tfvars' contains code for the following config variables:

* aws_region
* aws_profile (set locally in ~/.aws/credentials)
* aws_account_id (the id for the master aws account)
* integration_key (the Amazon-GuardDuty service integration key configured in pagerduty to integrate with AWS Guardduty)  
* users (admin aws iam  users)
* topic_arn = "arn:aws:sns:eu-west-1:[aws-account-id]:GuardDuty-notifications" (this is how it will be configured as an aws sns (simple notification service) topic 
* endpoint  = "https://events.pagerduty.com/integration/[pagerduty to AWS Guardduty integraion_key]/enqueue" this is required by the sns subscription endpoint configuration)

#### AWS Cloudwatch Event Rules File

'event-pattern.json'

* A json object that is used by 'AWS Cloudwatch Event Rules' to select 'AWS Guardduty Events' (findings) and route them to the AWS sns targets 


#### Trusted ip List File

'iplist.txt'

* A trusted ip list. GuardDuty does not generate findings for IP addresses that are included in this trusted IP list/s
At this point in time terraform is unable to update this list by 'terraform apply'. The list has to be manually deleted in the AWS dashboard >  Guardduty > Lists > Trusted IP Lists. Then you can run the 'terraform apply'.

#### Variables Initialisation File

'variables.tf'

* Used to set up the terraform variables and defaults required by terraform 'main.tf'


### 2 Pagerduty to Slack integration

This is is also set up utilising terraform separatly config here:

* https://github.com/ministryofjustice/cloudplatforms-terraform-ops/blob/master/main.tf
* https://github.com/ministryofjustice/cloudplatforms-terraform-ops/blob/master/services/amazon-guardduty-notifications/pagerduty.tf

### 3 Applying the terraform changes

```
terraform init
terraform plan
terraform apply (answer 'yes' to actually update remote config)
```
