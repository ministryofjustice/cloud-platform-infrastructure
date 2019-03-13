# IAM Policy to Restrict Regions and Enforce MFA

## Background
We do not wish to use non-EU AWS regions for strategic compliance and performance reasons. We would need a policy that no users in the AWS account can create resources outside of AWS EU regions.
 
AWS has few global resources like IAM, Cloudfront, ACM which work from us-east-1 region as root. Hence the us-east-1 region cannot be excluded for managing global services.

Also the Region restriction policy cannot be implemeted at Organisational Unit in the master AWS Account. Currently it has to be restricted through the user IAM policy by adding the condition - aws:RequestedRegion.

Reference -
* AWS Global Condition Context Keys - aws:RequestedRegion
https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html
* Easier way to control access to AWS regions using IAM policies
https://aws.amazon.com/blogs/security/easier-way-to-control-access-to-aws-regions-using-iam-policies/


The non-admin user IAM Policy with MFA and Region restriction looks like -
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
                }
            }
        }
    ]
}
```

## Description
The templates are standalone and do not depend on other templates for deployment. The parameters are declared in the templates and have to be provided as per the implementation

The templates aws-iam-adminandgroups.yaml, aws-iam-adminandroles.yaml implement assume role permissionns for a group of aws accounts. The roles and groups created by the templates are -
  - IAMAdminRole
  - BillingAdminRole
  - InfraAdminRole
  - NetworkAdminRole
  - UserDeveloperRole
  - UserDBARole
  - UserTesterRole
  - AuditAdminRole
  - UserLiveSupportRole
  - user-aws-support-managed-policy - The policy provides access for DBA, Tester and Dev users to AWS support
  - user-dba-managed-policy - The policy provides access to DBA users to start/stop DB instance, Create/Reboot/Delete Snapshot
  - user-parameter-store-managed-policy - The policy provides access for DBA, Tester and Dev user to manage parameters in parameter store
  - LZReadOnlyAccess - The policy that provides read only access to DBA, Tester, Dev & Live Support users
  - user-malicious-activity-deny-policy - The policy restricts the user roles, DBA, Test, Dev users from creating/modifying ec2, cloudtrail, iam, billing, kms resources

The template aws-iam-userpolicy-cli-mfa.yaml creates a user group, user role and attaches user self service iam policy to manage their MFA devices. The users can authenticate the mfa from cli when they assume the DevRole. The user policy consists of region restriction and is attached to the user role. New users will be added to the group and the user-self-service-policy will be inherited. They can perform IAM settings & MFA device updates without having to assume the role.

The template aws-iam-instanceprofiles.yaml has a list of IAM roles for the instances to use
  - rSysAdminRole-inst
  - rIAMAdminRole-inst
  - rInstanceOpsRole-inst
  - rInstanceOpsProfile-inst
  - rReadOnlyAdminRole-inst

Reference -
* Switching to an IAM Role (AWS CLI)
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-cli.html
* Switching to a Role (Console)
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-console.html

NOTE - To run AWS CLI commands using MFA authentication
Please refer to the steps in the link to generate the temporary session tokens, based on the MFA code. The temporary session token can be used as the 2FA 
Reference -
https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/


## Service Control Policy to Limit API access for users and services to EU-Region-only
When there is support for conditions in the Service Control Policy (SCP), the below policy can be applied at the Organisational Unit in the master AWS Account

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyAllOutsideEU",
            "Effect": "Deny",
            "Action": "*",
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:RequestedRegion": [
                        "eu-west-1",
                        "eu-west-2",
                        "eu-west-3",
                        "us-east-1"
                    ]
                }
            }
        }
    ]
}
```


# Other IAM Policies for Non-Admin IAM Users

## Deny policy
The Deny policy for the non-admin users in the account is below in the json format,

```
{
"Version": "2012-10-17",
"Statement": [
    {
      "Sid": "user-malicious-activity-deny-policy",
      "Effect": "Deny",
      "Action": [
        "ec2:AcceptVpcPeeringConnection",
        "ec2:AssociateRouteTable",
        "ec2:AttachInternetGateway",
        "ec2:AttachVpnGateway",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateCustomerGateway",
        "ec2:CreateDhcpOptions",
        "ec2:CreateNatGateway",
        "ec2:CreateNetworkAcl",
        "ec2:CreateNetworkAclEntry",
        "ec2:CreateRoute",
        "ec2:CreateRouteTable",
        "ec2:CreateVpc",
        "ec2:CreateVpcPeeringConnection",
        "ec2:CreateVpnConnection",
        "ec2:CreateVpnConnectionRoute",
        "ec2:CreateVpnGateway",
        "ec2:DeleteCustomerGateway",
        "ec2:DeleteDhcpOptions",
        "ec2:DeleteInternetGateway",
        "ec2:DeleteNatGateway",
        "ec2:DeleteNetworkAcl",
        "ec2:DeleteNetworkAclEntry",
        "ec2:DeleteRoute",
        "ec2:DeleteRouteTable",
        "ec2:DeleteSubnet",
        "ec2:DeleteVpc",
        "ec2:DeleteVpcPeeringConnection",
        "ec2:DeleteVpnConnection",
        "ec2:DeleteVpnConnectionRoute",
        "ec2:DeleteVpnGateway",
        "ec2:DisassociateAddress",
        "ec2:DisassociateRouteTable",
        "ec2:ReplaceNetworkAclAssociation",
        "ec2:ReplaceNetworkAclEntry",
        "ec2:TerminateInstances",
        "cloudtrail:DeleteTrail",
        "cloudtrail:StopLogging",
        "cloudtrail:UpdateTrail",
        "iam:AddRoleToInstanceProfile",
        "iam:AddUserToGroup",
        "iam:AttachGroupPolicy",
        "iam:AttachRolePolicy",
        "iam:AttachUserPolicy",
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:DeleteUserPolicy",
        "iam:PutGroupPolicy",
        "iam:PutRolePolicy",
        "iam:PutUserPolicy",
        "iam:UpdateAssumeRolePolicy",
        "aws-portal:ModifyAccount",
        "aws-portal:ModifyBilling",
        "aws-portal:ModifyPaymentMethods",
        "kms:DeleteAlias",
        "kms:ScheduleKeyDeletion",
        "kms:CreateGrant",
        "kms:PutKeyPolicy"
      ],
      "Resource": "*"
    }
  ]
}
```

## Non-Admin User Self Service policy
This is an IAM policy that allows IAM non-admin users to self-manage their MFA device.

```
 {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAllUsersToListAccounts",
      "Effect": "Allow",
      "Action": [
        "iam:ListAccountAliases",
        "iam:ListUsers",
        "iam:GetAccountPasswordPolicy",
        "iam:GetAccountSummary"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowIndividualUserToSeeAndManageOnlyTheirOwnAccountInformation",
      "Effect": "Allow",
      "Action": [
        "iam:ChangePassword",
        "iam:CreateAccessKey",
        "iam:CreateLoginProfile",
        "iam:DeleteAccessKey",
        "iam:DeleteLoginProfile",
        "iam:GetLoginProfile",
        "iam:ListAccessKeys",
        "iam:UpdateAccessKey",
        "iam:UpdateLoginProfile",
        "iam:ListSigningCertificates",
        "iam:DeleteSigningCertificate",
        "iam:UpdateSigningCertificate",
        "iam:UploadSigningCertificate",
        "iam:ListSSHPublicKeys",
        "iam:GetSSHPublicKey",
        "iam:DeleteSSHPublicKey",
        "iam:UpdateSSHPublicKey",
        "iam:UploadSSHPublicKey"
      ],
      "Resource": "arn:aws:iam::*:user/${aws:username}"
    },
    {
      "Sid": "AllowIndividualUserToListOnlyTheirOwnMFA",
      "Effect": "Allow",
      "Action": [
        "iam:ListVirtualMFADevices",
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
    }
  ]
}
```

Reference - https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_iam_mfa-selfmanage.html


# How to Deploy
* aws-iam-adminandgroups.yaml
```
GIT_DIR={git_dir}
AWS_PROFILE={aws_profile}

# Validate template
aws cloudformation validate-template --template-body file://$GIT_DIR/cloud-platform-infrastructure/cloudformation/aws-account-baseline-templates/aws-iam-user-roles-groups/aws-iam-adminandgroups.yaml --profile $AWS_PROFILE

# Deploy the template
aws cloudformation deploy --template-file $GIT_DIR/cloud-platform-infrastructure/cloudformation/aws-account-baseline-templates/aws-iam-user-roles-groups/aws-iam-adminandgroups.yaml --stack-name aws-iam-adminandgroups \\
--tags Owner={team_email} AgencyName={agency_name} ApplicationID=aws-iam Environment=Production \\
--capabilities CAPABILITY_NAMED_IAM \\
--profile $AWS_PROFILE
```

* aws-iam-adminandroles.yaml
```
GIT_DIR={git_dir}
AWS_PROFILE={aws_profile}

# Validate template
aws cloudformation validate-template --template-body file://$GIT_DIR/cloud-platform-infrastructure/cloudformation/aws-account-baseline-templates/aws-iam-user-roles-groups/aws-iam-adminandroles.yaml --profile $AWS_PROFILE

# Deploy the template
aws cloudformation deploy --template-file $GIT_DIR/cloud-platform-infrastructure/cloudformation/aws-account-baseline-templates/aws-iam-user-roles-groups/aws-iam-adminandroles.yaml --stack-name aws-iam-adminandroles \\
--tags Owner={team_email} AgencyName={agency_name} ApplicationID=aws-iam Environment=Production \\
--capabilities CAPABILITY_NAMED_IAM \\
--profile $AWS_PROFILE
```

* aws-iam-instanceprofiles.yaml
```
GIT_DIR={git_dir}
AWS_PROFILE={aws_profile}

# Validate template
aws cloudformation validate-template --template-body file://$GIT_DIR/cloud-platform-infrastructure/cloudformation/aws-account-baseline-templates/aws-iam-user-roles-groups/aws-iam-instanceprofiles.yaml --profile $AWS_PROFILE

# Deploy the template
aws cloudformation deploy --template-file $GIT_DIR/cloud-platform-infrastructure/cloudformation/aws-account-baseline-templates/aws-iam-user-roles-groups/aws-iam-instanceprofiles.yaml --stack-name aws-iam-instanceprofiles
--tags Owner={team_email} AgencyName={agency_name} ApplicationID=aws-iam Environment=Production \\
--capabilities CAPABILITY_NAMED_IAM \\
--profile $AWS_PROFILE
```

* aws-iam-userpolicy-cli-mfa.yaml
```
GIT_DIR={git_dir}
AWS_PROFILE={aws_profile}

# Validate template
aws cloudformation validate-template --template-body file://$GIT_DIR/cloud-platform-infrastructure/cloudformation/aws-account-baseline-templates/aws-iam-user-roles-groups/aws-iam-userpolicy-cli-mfa.yaml --profile $AWS_PROFILE

# Deploy the template
aws cloudformation deploy --template-file $GIT_DIR/cloud-platform-infrastructure/cloudformation/aws-account-baseline-templates/aws-iam-user-roles-groups/aws-iam-userpolicy-cli-mfa.yaml --stack-name aws-iam-userpolicy-cli-mfa \\
--tags Owner={team_email} AgencyName={agency_name} ApplicationID=aws-iam Environment=Production \\
--capabilities CAPABILITY_NAMED_IAM \\
--profile $AWS_PROFILE
```