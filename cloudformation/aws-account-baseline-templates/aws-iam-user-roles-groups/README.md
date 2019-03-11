# IAM Policy to Restrict Regions and Enforce MFA

## Background
We do not wish to use non-EU AWS regions for strategic compliance and performance reasons. We would eed a policy that no AWS account can create resources outside of AWS EU regions. 
AWS has few global resources like IAM, Cloudfront which work from us-east-1 region as root. So we have to include the us-east-1 region for managing global services.
Reference -
https://www.dawnbringer.net/blog/1057/AWS_Limit_API_Access

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "UserDeveloperPolicy",
            "Effect": "Allow",
            "Action": [
                "autoscaling:*",
                "cloudformation:*",
                "cloudwatch:*",
                "codebuild:*",
                "deploy",
                "dynamodb:*",
                "ec2:*",
                "ecs:*",
                "elasticbeanstalk:*",
                "elasticloadbalancing:*",
                "kms:*",
                "lambda:*",
                "logs:*",
                "rds:*",
                "route53:*",
                "s3:*",
                "sns:*"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": ["eu-west-1", "eu-west-2", "eu-west-3", "us-east-1"]
                },
                "Bool": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            }
        }
    ]
}
```

## To run AWS CLI commands using MFA authentication
Please refer to the steps in the link to generate the temporary session tokens, based on the MFA code. The temporary session token can be used as the 2FA 
Reference - 
https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/


# Other IAM Policies for Non-Admin IAM Users

## Deny policy
The Deny policy for the non-admin users in the account is below,

  MaliciousActivityDenyPolicy:
    Type: "AWS::IAM::ManagedPolicy"
    Properties:
      ManagedPolicyName: user-malicious-activity-deny-policy
      PolicyDocument:
        Version: "2012-10-17"
        Statement:
        - Effect: "Deny"
          Action:
          - "ec2:AcceptVpcPeeringConnection"
          - "ec2:AssociateRouteTable"
          - "ec2:AttachInternetGateway"
          - "ec2:AttachVpnGateway"
          - "ec2:AuthorizeSecurityGroupEgress"
          - "ec2:AuthorizeSecurityGroupIngress"
          - "ec2:CreateCustomerGateway"
          - "ec2:CreateDhcpOptions"
          - "ec2:CreateNatGateway"
          - "ec2:CreateNetworkAcl"
          - "ec2:CreateNetworkAclEntry"
          - "ec2:CreateRoute"
          - "ec2:CreateRouteTable"
          - "ec2:CreateVpc"
          - "ec2:CreateVpcPeeringConnection"
          - "ec2:CreateVpnConnection"
          - "ec2:CreateVpnConnectionRoute"
          - "ec2:CreateVpnGateway"
          - "ec2:DeleteCustomerGateway"
          - "ec2:DeleteDhcpOptions"
          - "ec2:DeleteInternetGateway"
          - "ec2:DeleteNatGateway"
          - "ec2:DeleteNetworkAcl"
          - "ec2:DeleteNetworkAclEntry"
          - "ec2:DeleteRoute"
          - "ec2:DeleteRouteTable"
          - "ec2:DeleteSubnet"
          - "ec2:DeleteVpc"
          - "ec2:DeleteVpcPeeringConnection"
          - "ec2:DeleteVpnConnection"
          - "ec2:DeleteVpnConnectionRoute"
          - "ec2:DeleteVpnGateway"
          - "ec2:DisassociateAddress"
          - "ec2:DisassociateRouteTable"
          - "ec2:ReplaceNetworkAclAssociation"
          - "ec2:ReplaceNetworkAclEntry"
          - "ec2:TerminateInstances"
          - "cloudtrail:DeleteTrail"
          - "cloudtrail:StopLogging"
          - "cloudtrail:UpdateTrail"
          - "iam:AddRoleToInstanceProfile"
          - "iam:AddUserToGroup"
          - "iam:AttachGroupPolicy"
          - "iam:AttachRolePolicy"
          - "iam:AttachUserPolicy"
          - "iam:DeleteRole"
          - "iam:DeleteRolePolicy"
          - "iam:DeleteUserPolicy"
          - "iam:PutGroupPolicy"
          - "iam:PutRolePolicy"
          - "iam:PutUserPolicy"
          - "iam:UpdateAssumeRolePolicy"
          - "aws-portal:ModifyAccount"
          - "aws-portal:ModifyBilling"
          - "aws-portal:ModifyPaymentMethods"
          - "kms:DeleteAlias"
          - "kms:ScheduleKeyDeletion"
          - "kms:CreateGrant"
          - "kms:PutKeyPolicy"
          Resource: "*"

## User Self Service policy
This is an IAM policy that allows IAM users to self-manage an MFA device.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListActions",
            "Effect": "Allow",
            "Action": [
                "iam:ListUsers",
                "iam:ListVirtualMFADevices"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowIndividualUserToListOnlyTheirOwnMFA",
            "Effect": "Allow",
            "Action": [
                "iam:ListMFADevices"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/*",
                "arn:aws:iam::*:user/${aws:username}"
            ]
        },
        {
            "Sid": "AllowIndividualUserToManageTheirOwnMFA",
            "Effect": "Allow",
            "Action": [
                "iam:CreateVirtualMFADevice",
                "iam:DeleteVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ResyncMFADevice"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/${aws:username}",
                "arn:aws:iam::*:user/${aws:username}"
            ]
        },
        {
            "Sid": "AllowIndividualUserToDeactivateOnlyTheirOwnMFAOnlyWhenUsingMFA",
            "Effect": "Allow",
            "Action": [
                "iam:DeactivateMFADevice"
            ],
            "Resource": [
                "arn:aws:iam::*:mfa/${aws:username}",
                "arn:aws:iam::*:user/${aws:username}"
            ],
            "Condition": {
                "Bool": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            }
        },
        {
            "Sid": "BlockMostAccessUnlessSignedInWithMFA",
            "Effect": "Deny",
            "NotAction": [
                "iam:CreateVirtualMFADevice",
                "iam:EnableMFADevice",
                "iam:ListMFADevices",
                "iam:ListUsers",
                "iam:ListVirtualMFADevices",
                "iam:ResyncMFADevice"
            ],
            "Resource": "*",
            "Condition": {
                "BoolIfExists": {
                    "aws:MultiFactorAuthPresent": "false"
                }
            }
        }
    ]
}
```

Reference - https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_iam_mfa-selfmanage.html

# How to Deploy
The templates are standalone and do not depend on other templates for deployment. The parameters are declared in the templates and have to be provided as per the implementation
The templates aws-iam-adminandgroups.yaml, aws-iam-adminandroles.yaml implement assume role permissionns for a group of aws accounts.
The template aws-iam-userpolicy-cli-mfa.yaml creates a user group, user role and attaches user self service iam policy to manage their MFA devices and also enforce MFA.
The template aws-iam-instanceprofiles.yaml has a list of IAM roles for the instances to use

