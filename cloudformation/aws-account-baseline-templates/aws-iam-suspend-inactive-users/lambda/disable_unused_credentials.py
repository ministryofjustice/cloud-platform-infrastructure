#==================================================================================================
# Function: DisableUnusedCredentials
# Purpose:  Disables unused access keys older than the given period.
#==================================================================================================

import boto3, json, datetime, os
from time import gmtime, strftime
from datetime import date

DEFAULT_AGE_THRESHOLD_IN_DAYS = 120
CREATE_DATE_AGE_THRESHOLD_IN_DAYS = 7

#==================================================================================================
# Function handler
#==================================================================================================
def lambda_handler(event, context):

    return_value = {} 
    return_value['DeletedPasswords'] = []
    return_value['DisabledAccessKeys'] = []
    return_value['SuspendedUsers'] = []
    date_fmt = strftime("%d_%m_%Y_%H:%M:%S", gmtime())              #get to the current date
    suspended_users_group = os.environ['SUSPENDED_USERS_GROUP']
    sns_topic_arn = os.environ['TOPIC_ARN']
    account_id = context.invoked_function_arn.split(":")[4]

    client = boto3.client('iam')

    now = date(datetime.date.today().year, datetime.date.today().month, datetime.date.today().day)

    # For each user, determine:
    # (1) the create date for the user or access key is less than 7 days or check if user has Admin privileges
    # (2) the status of all the access keys
    # (3) the console login status
    # (4) if console login and access key are inactive, move to suspended users group
    for user in client.list_users(MaxItems=500)['Users']:
        active_login_profile = "true"
        active_access_key = "true"
        check_user = "true"
        access_key_count = 0
        inactive_access_key_count = 0
        login_create_date = client.get_user(UserName = user['UserName'])['User']['CreateDate']
        login_create_date = date(login_create_date.year, login_create_date.month, login_create_date.day)
        login_age = (now - login_create_date).days
        if (login_age <= CREATE_DATE_AGE_THRESHOLD_IN_DAYS):
            print('User {0} was created less than 7days ago. Skip'.format(user['UserName']))
            check_user = "false"
        else:
            for access_key in client.list_access_keys(UserName = user['UserName'])['AccessKeyMetadata']:
                access_key_create_date = date(access_key['CreateDate'].year, access_key['CreateDate'].month, access_key['CreateDate'].day)
                access_key_age = (now - access_key_create_date).days
                if (access_key_age <= CREATE_DATE_AGE_THRESHOLD_IN_DAYS):
                    print('User {0} has access key {1} that was created less than 7days ago. Skip'.format(user['UserName'],access_key['AccessKeyId']))
                    check_user = "false"
                    break
            for group in client.list_groups_for_user(UserName = user['UserName'])['Groups']:
                if group['GroupName'] == suspended_users_group :
                    print ('User {0} is in SuspendedUsersGroup. Skip'.format(user['UserName']))
                    check_user = "false"
                    break
                for group_policy in client.list_attached_group_policies(GroupName = group['GroupName'])['AttachedPolicies']:
                    if group_policy['PolicyName'] == "AdministratorAccess" :
                        check_user = "false"
                        print ('User {0} has Admin Access through group policy in {1}. Skip'.format(user['UserName'],group['GroupName']))
                        break
                for attached_policy in client.list_attached_user_policies(UserName = user['UserName'])['AttachedPolicies']:
                    if attached_policy['PolicyName'] == "AdministratorAccess" : 
                        check_user = "false"
                        print ('User {0} has Admin Access with AWS managed policy. Skip'.format(user['UserName']))
        if (check_user == "true") :
            # Check if there is no access key
            if (client.list_access_keys(UserName = user['UserName'])['AccessKeyMetadata'] == []):
                active_access_key = "false"
                print ('User {0} never had access key'.format(user['UserName']))
            # Check for all the access keys of User
            for access_key in client.list_access_keys(UserName = user['UserName'])['AccessKeyMetadata']:
                access_key_count += 1
                if access_key['Status'] == 'Active':
                    response = client.get_access_key_last_used(AccessKeyId = access_key['AccessKeyId'])
                    if 'LastUsedDate' in response['AccessKeyLastUsed'] :
                        access_key_last_used_date = response['AccessKeyLastUsed']['LastUsedDate']
                        access_key_last_used_date = date(access_key_last_used_date.year, access_key_last_used_date.month, access_key_last_used_date.day)
                        age = (now - access_key_last_used_date).days
                        if age > DEFAULT_AGE_THRESHOLD_IN_DAYS:
                            print('The access key {0} for the user {1} has not been used in {2} days, DISABLING access key'.format(access_key['AccessKeyId'], user['UserName'], age))
                            response = client.update_access_key(
                                UserName = user['UserName'],
                                AccessKeyId = access_key['AccessKeyId'],
                                Status = 'Inactive')
                            return_value['DisabledAccessKeys'].append({'UserName': user['UserName'], 'LastUsedDate': str(access_key_last_used_date)})
                    else:
                        print('User {0} has not used access key {1}. DISABLING access key'.format(user['UserName'], access_key['AccessKeyId']))
                        response = client.update_access_key(
                            UserName = user['UserName'],
                            AccessKeyId = access_key['AccessKeyId'],
                            Status = 'Inactive')
                        return_value['DisabledAccessKeys'].append({'UserName': user['UserName'], 'LastUsedDate': ''})
                else:
                    inactive_access_key_count += 1
                    print ('User {0} has Inactive access key {1}'.format(user['UserName'], access_key['AccessKeyId']))
            # If all the user access keys are inactive
            if (access_key_count == inactive_access_key_count):
                active_access_key = "false"
                print ('User {0} has {1} Active and {2} Inactive access keys'.format(user['UserName'],(access_key_count - inactive_access_key_count),inactive_access_key_count))
            # Check status of console login
            if 'PasswordLastUsed' in user:
                password_last_used = date(user['PasswordLastUsed'].year, user['PasswordLastUsed'].month, user['PasswordLastUsed'].day)
                age = (now - password_last_used).days
                if age > DEFAULT_AGE_THRESHOLD_IN_DAYS:
                    # Disable the user's password (delete login profile).
                    try:
                        if client.get_login_profile(UserName = user['UserName']):
                            print('The user {0} has not logged in to the console in {1} days, DELETING password'.format(user['UserName'], age))
                            response = client.delete_login_profile(UserName = user['UserName'])
                            return_value['DeletedPasswords'].append({'UserName': user['UserName'], 'PasswordLastUsed': str(user['PasswordLastUsed'])})
                    except:
                        print('No login profile exists for {0} '.format(user['UserName']))
                        active_login_profile = "false" 
                    if client.list_mfa_devices(UserName = user['UserName']):
                        for mfa_device in client.list_mfa_devices(UserName = user['UserName'])['MFADevices']:
                            print('Deactivating MFA device for user')
                            response = client.deactivate_mfa_device(UserName = user['UserName'], SerialNumber = mfa_device['SerialNumber'])
                    else:
                        print('No MFA device exists for {0}'.format(user['UserName']))
            else:
                try:
                    if client.get_login_profile(UserName = user['UserName']):
                        print('The user {0} has never logged in to the console, DELETING password'.format(user['UserName']))
                        response = client.delete_login_profile(UserName = user['UserName'])
                        return_value['DeletedPasswords'].append({'UserName': user['UserName'], 'PasswordLastUsed': str(user['PasswordLastUsed'])})
                except:
                    print('No login profile exists for {0}. It may been already been deleted.'.format(user['UserName']))
                    active_login_profile = "false"
            # Move Inactive Users to Suspended Users Group with DenyAll access
            if ( (active_login_profile == "false") and (active_access_key == "false") ):
                print ('moving User {0} to {1}'.format(user['UserName'], suspended_users_group))
                for inline_policy in client.list_user_policies(UserName = user['UserName'])['PolicyNames']:
                    print ('Removing Inline Policy {0}'.format(inline_policy))
                    response = client.delete_user_policy(UserName = user['UserName'], PolicyName = inline_policy)
                for attached_policy in client.list_attached_user_policies(UserName = user['UserName'])['AttachedPolicies']:
                    print ('Removing Attached Policy {0}'.format(attached_policy['PolicyArn']))
                    response = client.detach_user_policy(UserName = user['UserName'], PolicyArn = attached_policy['PolicyArn'])
                for group in client.list_groups_for_user(UserName = user['UserName'])['Groups']:
                    print ('User {0} is removed from group {1}'.format(user['UserName'], group['GroupName']))
                    response = client.remove_user_from_group(UserName = user['UserName'], GroupName = group['GroupName'])
                print ('User {0} has been added to {1}'.format(user['UserName'], suspended_users_group))
                response = client.add_user_to_group(UserName = user['UserName'], GroupName = suspended_users_group)
                return_value['SuspendedUsers'].append({'UserName': user['UserName']})

    if (return_value['DeletedPasswords'] == [] and return_value['DisabledAccessKeys'] == [] and return_value['SuspendedUsers'] == []):
        print ("Nothing to SNS")
    else:
        # SNS topic Section
        sns_client       = boto3.client('sns',region_name='eu-west-1')
        subject          = 'AWS Account - ' + account_id + ' Inactive User List ' + date_fmt
        message_body     = '\n' + "DeletedPasswords are " + str(return_value['DeletedPasswords'])
        message_body     += '\n' + "DisabledAccessKeys are " + str(return_value['DisabledAccessKeys'])
        message_body     += '\n' + "SuspendedUsers are " + str(return_value['SuspendedUsers'])
        sns_client.publish(TopicArn=sns_topic_arn, Message=message_body, Subject=subject)

    return return_value