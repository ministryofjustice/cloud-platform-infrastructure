# AWS Limit Monitor

The AWS Limit monitor leverages AWS Trusted Advisor service limit checks that display your usage and limits for specific AWS services.
An AWS Lambda function runs once every 24 hours and checks to retrieve the most current utilisation and limit data through API calls.  

Limit Status:

| Status | Utilisation | 
| - | - |
| OK | Less than 80% |
| WARN | 80%-99% |
| ERROR | 100% |




## Configuration

The following table lists the configurable parameters and their default values.

| Parameter | Description | Default |
| - | - | - |
| SNSEmail | (Required) The email address to subscribe for alert messages | platforms@digital.justice.gov.uk |
| SNSEvents | List of alert levels to send email alerts in response to | "ERROR" |
| SlackEvents | List of alert levels to send Slack alerts in response to | "WARN","ERROR" |
| SlackHookURL | SSM parameter key for incoming Slack web hook URL | limit_monitor_slack_webhook |
| SlackChannel | SSM parameter key for the Slack channel | limit_monitor_slack_channel |

Once cloudformation has completed creating the stack, you will need to enter the real slack webhook and channel names in the AWS Parameter Store and replace the dummy entries. 

Click [here](https://docs.aws.amazon.com/solutions/latest/limit-monitor/welcome.html) for official AWS documentation 

Click [here](https://github.com/awslabs/aws-limit-monitor) for Github repository 