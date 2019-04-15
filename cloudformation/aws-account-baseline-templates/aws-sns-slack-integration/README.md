# AWS SNS Slack Integration
This section explains how to create a function to integrate AWS SNS to Slack. It consists of a lambda function that takes in the parameters the name for the lambda function, the existing Slack Webhook Url and the existing Slack Channel Name. 

To create the incoming webhook for a new Slack channel, follow the [link](https://api.slack.com/incoming-webhooks)


## How to Deploy
Parameters -
Slack Webhook Url
Slack Channel Name

```bash
# parameters
AWS_PROFILE={aws_profile_name}
SLACK_CHANNELNAME={existing_slack_channel_name}
SLACK_HOOK_URL={existing-slack-channel-webhook-url}
ACCOUNT_EMAIL={account_email}
AGENCY_NAME={agency_name}

export AWS_PROFILE
export SLACK_CHANNELNAME
export SLACK_HOOK_URL
export ACCOUNT_EMAIL
export AGENCY_NAME

# validate the template
aws cloudformation validate-template --template-body file://aws-sns-slack-integration.yaml --profile $AWS_PROFILE

# deploy the template
aws cloudformation create-stack --stack-name aws-sns-slack-integration --template-body file://aws-sns-slack-integration.yaml --parameters ParameterKey=pLambdaFunctionName,ParameterValue=AWSSlackSNSFunction ParameterKey=pSlackChannelName,ParameterValue=$SLACK_CHANNELNAME ParameterKey=pSlackHookUrl,ParameterValue=$SLACK_HOOK_URL  --tags Key=Owner,Value=$ACCOUNT_EMAIL Key=AgencyName,Value=$AGENCY_NAME Key=ApplicationID,Value=aws-sns Key=Environment,Value=Production --capabilities CAPABILITY_NAMED_IAM --profile $AWS_PROFILE

```
