#==================================================================================================
# Function: DeleteUsersInSuspendedUsersGroup
# Purpose:  Delete Users In the SuspendedUsersGroup
#==================================================================================================

import boto3, json, datetime, os
from time import gmtime, strftime
from datetime import date

DEFAULT_AGE_THRESHOLD_IN_DAYS = 130

#==================================================================================================
# Function handler
#==================================================================================================
def lambda_handler(event, context):

return_value = {}
return_value['DeletedUsers'] = []
now = date(datetime.date.today().year, datetime.date.today().month, datetime.date.today().day)
suspended_users_group = os.environ['SUSPENDED_USERS_GROUP']
sns_topic_arn = os.environ['TOPIC_ARN']
account_id = context.invoked_function_arn.split(":")[4]
date_fmt = strftime("%d_%m_%Y_%H:%M:%S", gmtime())              #get to the current date

client = boto3.client('iam')

print ('Deleting the Users In SuspendedUserGroup')
for user in client.get_group(GroupName = suspended_users_group)['Users']:
    if 'CreateDate' in user :
    user_created_date = user['CreateDate']
    user_created_date = date(user_created_date.year, user_created_date.month, user_created_date.day)
    age = (now - user_created_date).days
    if age > DEFAULT_AGE_THRESHOLD_IN_DAYS:
        print ('Deleting User {0}'.format(user['UserName']) )
        response = client.delete_user(UserName = user['UserName'])
        return_value['DeletedUsers'].append({'UserName': user['UserName'], 'CreateDate': str(user_created_date)})

if (return_value['DeletedUsers'] == []):
    print ("Nothing to SNS")
else:
    # SNS topic Section
    sns_client       = boto3.client('sns',region_name='eu-west-1')
    subject          = 'AWS Account - ' + account_id + ' Users Deleted from SuspendedUserGroup ' + date_fmt
    message_body     = '\n' + "Deleted Users are " + str(return_value['DeletedUsers']) + ' \n '
    sns_client.publish(TopicArn=sns_topic_arn, Message=message_body, Subject=subject)

return return_value