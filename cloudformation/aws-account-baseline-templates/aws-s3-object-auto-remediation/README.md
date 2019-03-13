# Auto Remediate Unintended Permissions change on S3 Objects

## Background
AWS S3 buckets are often accidentally left public, resulting in the accidental disclosure of confidential data to everyone. Also if the number of objects and users in the AWS account are large, ensuring that the ACLs are correctly configured to the objects can be a challenge. 
We want to ensure that public access to AWS S3 storage is intentional, to avoid the unintended update with public permissions. The template is a reactive approach in situations where the change on the ACL is accidental and must be fixed.

References - 
* https://aws.amazon.com/blogs/security/how-to-use-bucket-policies-and-apply-defense-in-depth-to-help-secure-your-amazon-s3-data/
* https://aws.amazon.com/blogs/security/how-to-detect-and-automatically-remediate-unintended-permissions-in-amazon-s3-object-acls-with-cloudwatch-events/

## How to Deploy
Parameters -
Create New Private Bucket or Chose Existing Bucket
Create Object level logging for the Private bucket
Create S3 Bucket for the Object level logging
Create Lambda function, Role permissions
Create SNS Topic with Slack integration or chose existing SNS topic

```
# parameters
AWS_PROFILE={aws_profile_name}
export AWS_PROFILE

# validate the template
aws cloudformation validate-template --template-body file://aws-s3-object-auto-remediation.yaml --profile $AWS_PROFILE

# deploy the template
aws cloudformation deploy --template-file aws-s3-object-auto-remediation.yaml --stack-name s3-object-auto-remediate \\
--parameter-overrides ParameterKey=pCreateS3PrivateBucket,ParameterValue=false ParameterKey=pS3PrivateBucketName,ParameterValue= ParameterKey=pExistingPrivateBucketName,ParameterValue={existing-s3-bucket-name} ParameterKey=pS3ObjectTrailBucketName,ParameterValue=bucket-for-s3-object-level-trail ParameterKey=pObjectCloudTrailName,ParameterValue=s3-object-level-trail ParameterKey=pLambdaFunctionName,ParameterValue=CheckAndCorrectObjectACL ParameterKey=pEventsRuleName,ParameterValue=S3ObjectACLAutoRemediate ParameterKey=pLambdaExecutionRoleName,ParameterValue=AllowLogsAndS3ACL ParameterKey=pCreateSnsTopic,ParameterValue=false ParameterKey=pExistingSnsTopic,ParameterValue={existing-sns-topic-arn} ParameterKey=pSlackChannelName,ParameterValue= ParameterKey=pSlackHookUrl,ParameterValue= \\
--tags Owner={team_email} AgencyName={agency_name} ApplicationID=aws-s3 Environment=Production \\
--capabilities CAPABILITY_NAMED_IAM \\
--profile $AWS_PROFILE

```

## IAM User Policy to prevent Public Permissions
The proactive approach is to restrict user permissions from having the access to update to public permissions. The IAM policy is set with conditions to force the users to put objects with private access.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyPublicCannedAcl",
            "Effect": "Deny",
            "Action": [
              "s3:PutBucketAcl",
              "s3:PutObjectAcl",
              "s3:PutObjectVersionAcl"
            ],
            "Resource": [
              "arn:aws:s3:::{bucket_name}",
              "arn:aws:s3:::{bucket_name}/*"
            ],
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": [
                        "public-read",
                        "public-read-write",
                        "authenticated-read"
                    ]
                }
            }
        }
    ]
}

```


