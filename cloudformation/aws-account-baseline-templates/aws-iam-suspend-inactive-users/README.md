# AWS IAM Suspend Inactive Users
This section explains how to deploy the template to continuosly monitor for inactive IAM users in the AWS account

* [Check Inactive IAM Users in AWS Account](#Check-Inactive-IAM-Users-in-AWS-Account)
* [How to Deploy](#How-to-Deploy)


# Check Inactive IAM Users in AWS Account

## Description
To increase the security of the AWS account, we need to remove IAM user credentials (that is, passwords and access keys) that are not needed. For example, when users leave the organization or no longer need AWS access, we need to ensure their credentials are no longer operational. Ideally, the credentials should be deleted, if they are no longer needed. The accounts can be recreated at a later date if the need arises. At the very least, we need to delete the password and deactivate the access keys, so that the former users no longer have access.

The template deactivates unused credentials, if they have not been used for *120days* and then moves the user accounts to the SuspendedUsersGroup. The SuspendedUsersGroup will have DenyAll IAM policy and the user will have no access to AWS services. The users in SuspendedUsersGroup will be checked and deleted after *10days* of being in the group. Also recently created user profile or access key that has not been used for more than 7 days, are deactivated.

There are three lambda functions which carry out the task.

Lambda1 - DisableUnusedCredentials will run everyday Monday-friday 9AM UTC and checks if the user accounts have not been used. It moves inactive user accounts (inactive console login and inactive access keys) to the SuspendedUsersGroup. It sends sns notification of DeletedPasswords, InactiveAccessKeys, users moved to SuspendedUsersGroup

Lambda2 - DeleteUsersInSuspendedUsersGroup deletes user accounts from the SuspendedUserAccounts. It sends sns notification of user accounts deleted from the SuspendedUsersGroup

Lambda3 - Slack Integration which outputs the result of Lambda1 and Lambda2 execution to the slack

EXCEPTION - Users with Admin privileges obtained through AWS Managed Policy are not checked for inactive status. Users with Admin privileges obtained through Inline Policy will be checked for inactive status.

## How to Deploy

### Prerequisites
Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) and [configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) access keys using the below commands:

```bash
sudo apt-get install -y python-dev python-pip
sudo pip install awscli
aws --version
aws configure
``` 

### Parameters
The IAM user or the access key is made Inactive if they have not logged in or used the access key for DEFAULT_AGE_THRESHOLD_IN_DAYS which is currently set to 120 days

A New IAM user or a New access key is not checked for inactive status for CREATE_DATE_AGE_THRESHOLD_IN_DAYS which is currently set as 7 days

### Package the template 
The script package_template.sh uses AWS CLI commands to package the lambda and the template

```bash
#!/bin/bash
set +x

# parameters
AWS_PROFILE={aws_profile_name}
EXISTING_S3BUCKETNAME={existing_s3_bucket_in_the_aws_account}
EXISTING_SNS_TOPIC_ARN={existing_sns_topic_arn}
ACCOUNT_EMAIL={account_email}
AGENCY_NAME={agency_name}

export AWS_PROFILE
export EXISTING_S3BUCKETNAME
export EXISTING_SNS_TOPIC_ARN
export ACCOUNT_EMAIL
export AGENCY_NAME

# package template
aws cloudformation package --template-file aws-iam-suspend-inactive-users.yaml --s3-bucket $EXISTING_S3BUCKETNAME --output-template-file aws-iam-suspend-inactive-users-output.yaml --profile $AWS_PROFILE

# validate the template
aws cloudformation validate-template --template-body file://aws-iam-suspend-inactive-users-output.yaml --profile $AWS_PROFILE 

# deploy the template
aws cloudformation deploy --template-file aws-iam-suspend-inactive-users-output.yaml --stack-name aws-iam-suspend-inactive-users  --parameter-overrides pCreateSnsTopic=false pSlackChannelName= pSlackHookUrl= pExistingSnsTopic=$EXISTING_SNS_TOPIC_ARN --tags Owner=$ACCOUNT_EMAIL AgencyName=$AGENCY_NAME ApplicationID=aws-iam Environment=Production --capabilities CAPABILITY_NAMED_IAM --profile $AWS_PROFILE

```

