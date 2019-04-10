#!/bin/bash
set +x
#########################
# Replace Values in {} 
#########################

# parameters
AWS_PROFILE={aws_profile_name}
S3BUCKETNAME={new_bucket_name}
EXISTING_SNS_TOPIC_ARN={existing_sns_topic_arn}
ACCOUNT_EMAIL={account_email}
AGENCY_NAME={agency_name}
export AWS_PROFILE
export S3BUCKETNAME
export EXISTING_SNS_TOPIC_ARN
export ACCOUNT_EMAIL
export AGENCY_NAME

# create bucket & package template
aws s3 mb s3://$S3BUCKETNAME --profile $AWS_PROFILE
aws cloudformation package --template-file aws-iam-suspend-inactive-users.yaml --s3-bucket $S3BUCKETNAME --output-template-file aws-iam-suspend-inactive-users-output.yaml --profile $AWS_PROFILE
aws s3 ls s3://$S3BUCKETNAME --profile $AWS_PROFILE

# validate the template
aws cloudformation validate-template --template-body file://aws-iam-suspend-inactive-users-output.yaml --profile $AWS_PROFILE

# deploy the template
aws cloudformation deploy --template-file aws-iam-suspend-inactive-users-output.yaml --stack-name aws-iam-suspend-inactive-users --parameter-overrides ParameterKey=pCreateSnsTopic,ParameterValue=false ParameterKey=pSlackChannelName,ParameterValue= ParameterKey=pSlackHookUrl,ParameterValue= ParameterKey=pExistingSnsTopic,ParameterValue=$EXISTING_SNS_TOPIC_ARN --tags Owner=$ACCOUNT_EMAIL AgencyName=$AGENCY_NAME ApplicationID=aws-iam Environment=Production --capabilities CAPABILITY_NAMED_IAM --profile $AWS_PROFILE

