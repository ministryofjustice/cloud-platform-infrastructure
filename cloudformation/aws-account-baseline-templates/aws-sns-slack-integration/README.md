# AWS SNS Slack Integration
This section explains how to create a function to integrate AWS SNS to Slack. It consists of a lambda function that takes in the parameters the name for the lambda function, the existing Slack Webhook Url and the existing Slack Channel Name. 

To create the incoming webhook for a new Slack channel, follow the [link](https://api.slack.com/incoming-webhooks)


## How to Deploy
Parameters -
Lambda Function Name
Slack Webhook Url
Slack Channel Name

```
# parameters
AWS_PROFILE={aws_profile_name}
export AWS_PROFILE

# validate the template
aws cloudformation validate-template --template-body file://aws-sns-slack-integration.yaml --profile $AWS_PROFILE

# deploy the template
aws cloudformation create-stack --stack-name aws-sns-slack-integration --template-body file://aws-sns-slack-integration.yaml --parameters ParameterKey=pLambdaFunctionName,ParameterValue=AWSSlackSNSFunction ParameterKey=pSlackChannelName,ParameterValue={existing_slack_channel_name} ParameterKey=pSlackHookUrl,ParameterValue={existing-slack-channel-webhook-url}  --tags Key=Owner,Value={team-email} Key=AgencyName,Value={agency-name} Key=ApplicationID,Value=aws-sns Key=Environment,Value=Production --capabilities CAPABILITY_NAMED_IAM --profile $AWS_PROFILE

```
