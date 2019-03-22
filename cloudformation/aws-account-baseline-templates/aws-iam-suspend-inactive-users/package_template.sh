#!/bin/bash
set +x
#########################
# Replace Values in {} 
#########################

# parameters
AWS_PROFILE={aws_profile_name}
S3BUCKETNAME={new_bucket_name}
export AWS_PROFILE
export S3BUCKETNAME

# create bucket & package template
aws s3 mb s3://$S3BUCKETNAME --profile $AWS_PROFILE
aws cloudformation package --template-file check_inactive_users.yaml --s3-bucket $S3BUCKETNAME --output-template-file check_inactive_users-output.yaml --profile $AWS_PROFILE
aws s3 ls s3://$S3BUCKETNAME --profile $AWS_PROFILE

# validate the template
aws cloudformation validate-template --template-body file://check_inactive_users-output.yaml --profile $AWS_PROFILE 

# deploy the template
aws cloudformation deploy --template-file check_inactive_users-output.yaml --stack-name check-inactive-users --parameter-overrides ParameterKey=pCreateSnsTopic,ParameterValue=false ParameterKey=pSlackChannelName,ParameterValue= ParameterKey=pSlackHookUrl,ParameterValue= ParameterKey=pExistingSnsTopic,ParameterValue={existing_sns_topic_arn} --tags Owner={account_email} AgencyName={agency_name} ApplicationID=aws-iam Environment=Production --capabilities CAPABILITY_NAMED_IAM --profile $AWS_PROFILE

