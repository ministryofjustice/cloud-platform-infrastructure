#==================================================================================================
# Function: 
# Purpose:  A Python function to list the AWS S3 buckets in the account that do not have
# encryption status and apply the default encryption
#==================================================================================================

import boto3, json, datetime, os, sys
from time import gmtime, strftime
from datetime import date

#==================================================================================================
# Function handler
#==================================================================================================
def lambda_handler(event, context):
    
    buckets = {}
    buckets['Encryption_Applied'] = []
    #buckets['Already_Encrypted'] = []
    
    date_fmt = strftime("%d_%m_%Y_%H:%M:%S", gmtime())              #get to the current date
    account_id = context.invoked_function_arn.split(":")[4]
    sns_topic_arn = os.environ['TOPIC_ARN']
    s3_bucket_exception_list = os.environ['S3_EXCEPTION']

    s3client = boto3.client('s3')

    print(boto3.__version__)
    
    try:
        # describe buckets
        list_bucket_response = s3client.list_buckets()
        for bucket_dictionary in list_bucket_response['Buckets']:
            if bucket_dictionary['Name'] not in s3_bucket_exception_list:
                try:
                    bucket_encryption_response = s3client.get_bucket_encryption(Bucket=bucket_dictionary['Name'])
                    for rules in bucket_encryption_response['ServerSideEncryptionConfiguration']['Rules']:
                        for value in rules['ApplyServerSideEncryptionByDefault'].items():
                            if (str(value) in ('AES256','aws:kms')):
                                print ("\n{0} is already encrypted".format(bucket_dictionary['Name']))
                    #buckets['Already_Encrypted'].append(bucket_dictionary['Name'])
                except:
                    print ("\n{0} unencrypted".format(bucket_dictionary['Name']))
                    response = s3client.put_bucket_encryption(
                        Bucket=bucket_dictionary['Name'],
                        ServerSideEncryptionConfiguration={
                            'Rules': [{
                                'ApplyServerSideEncryptionByDefault': {'SSEAlgorithm': 'AES256'}
                            }, ]
                        })
                    print ("Default Encryption applied")
                    buckets['Encryption_Applied'].append(bucket_dictionary['Name'])

        if (buckets['Encryption_Applied'] == []):
            print ("Nothing to SNS")
        else:
            # SNS topic Section
            sns_client       = boto3.client('sns',region_name='eu-west-1')
            subject          = 'AWS Account - ' + account_id + ' S3 Bucket Encryption Status ' + date_fmt
            message_body     = '\n' + "Encryption applied to S3 buckets are " + str(buckets)
            sns_client.publish(TopicArn=sns_topic_arn, Message=message_body, Subject=subject)
    
        return buckets

    except:
        err = 'Error'
        for e in sys.exc_info():
            err += str(e)
        print("error {0}".format(err))
