#==================================================================================================
# Function: 
# Purpose:  A Python function to list out any AWS S3 buckets in the account that have 
# public access based on their ACLs, either Read or Write permissions.
#==================================================================================================

import boto3, json, datetime, os, sys
from time import gmtime, strftime
from datetime import date

#==================================================================================================
# Function handler
#==================================================================================================
def lambda_handler(event, context):

    private_buckets = {} 
    private_buckets['PublicAccessBlock'] = []
    date_fmt = strftime("%d_%m_%Y_%H:%M:%S", gmtime())              #get to the current date
    sns_topic_arn = os.environ['TOPIC_ARN']
    s3_bucket_exception_list = os.environ['S3_EXCEPTION']
    account_id = context.invoked_function_arn.split(":")[4]

    s3client = boto3.client('s3')

    public_acl_indicator = ['http://acs.amazonaws.com/groups/global/AllUsers','http://acs.amazonaws.com/groups/global/AuthenticatedUsers']
    permissions_to_check = ['READ', 'WRITE']
    public_buckets = {}
    print(boto3.__version__)
    
    try:
        # describe all S3 buckets
        list_bucket_response = s3client.list_buckets()
        for bucket_dictionary in list_bucket_response['Buckets']:
            if bucket_dictionary['Name'] not in s3_bucket_exception_list:
                is_public_bucket = "false"
                bucket_acl_response = s3client.get_bucket_acl(Bucket=bucket_dictionary['Name'])
                for grant in bucket_acl_response['Grants']:
                    for (key, value) in grant.items():
                        if key == 'Permission' and any(permission in value for permission in permissions_to_check):
                            for (grantee_attrib_key, grantee_attrib_value) in grant['Grantee'].items():
                                if 'URI' in grantee_attrib_key and grant['Grantee']['URI'] in public_acl_indicator:
                                    is_public_bucket = "true"
                                    if value not in public_buckets:
                                        public_buckets[value] = [bucket_dictionary['Name']]
                                    else:
                                        public_buckets[value] += [bucket_dictionary['Name']]
                # If bucket is private
                if (is_public_bucket == "false"):
                    print ("\nbucket {0} is PRIVATE".format(bucket_dictionary['Name']))
                    try:
                        response = s3client.get_public_access_block(Bucket=bucket_dictionary['Name'])
                        count = 0
                        for key, value in response['PublicAccessBlockConfiguration'].items():
                            # print ("public access block {0} {1} ".format(key, value))
                            if ( str(value) == "False" ):
                                print ("public access block already configured but set to false. changing permissions to true")
                                response = s3client.put_public_access_block(
                                    Bucket=bucket_dictionary['Name'],
                                    PublicAccessBlockConfiguration={
                                        'BlockPublicAcls': True,
                                        'IgnorePublicAcls': True,
                                        'BlockPublicPolicy': True,
                                        'RestrictPublicBuckets': True
                                })
                                print ("public access block applied")
                                private_buckets['PublicAccessBlock'].append(bucket_dictionary['Name'])
                                break
                            else:
                                count += 1
                        if (count == 4):
                            print ("{0} has public access block correctly configured".format(bucket_dictionary['Name']))
                    except:
                        response = s3client.put_public_access_block(
                            Bucket=bucket_dictionary['Name'],
                            PublicAccessBlockConfiguration={
                                'BlockPublicAcls': True,
                                'IgnorePublicAcls': True,
                                'BlockPublicPolicy': True,
                                'RestrictPublicBuckets': True
                            })
                        print ("public access block applied")
                        private_buckets['PublicAccessBlock'].append(bucket_dictionary['Name'])
                else:
                    print ("\nbucket {0} is PUBLIC, skip public access block".format(bucket_dictionary['Name']))

        print("\nPrivate Buckets that have been updated with Public Access Block permissions are {0}".format(private_buckets['PublicAccessBlock']))

        if (private_buckets['PublicAccessBlock'] == []):
            print ("Nothing to SNS")
        else:
            # SNS topic Section
            sns_client       = boto3.client('sns',region_name='eu-west-1')
            subject          = 'AWS Account - ' + account_id + ' S3 Bucket Status ' + date_fmt
            message_body     = '\n' + "S3 Private Buckets updated with Public Access Block permissions " + str(private_buckets)
            sns_client.publish(TopicArn=sns_topic_arn, Message=message_body, Subject=subject)
        
        return public_buckets

    except:
        err = 'Error'
        for e in sys.exc_info():
            err += str(e)
        print("error {0}".format(err))
