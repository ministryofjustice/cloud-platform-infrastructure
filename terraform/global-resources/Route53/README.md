# Setup a new subdomain in the cloud-platform account

Terraform created to manage delegated hosted zones in the cloud-platfoem-aws account.


### Set environment variables.

```
$ export AWS_PROFILE=<profile_name>
$ export KOPS_STATE_STORE=s3://route53-terraform
```

### Add new Hosted Zone

Edit `variables.tf` with new hosted zone name

To run you need to execute the below in the terraform directory:

```
$ Terraform init
$ Terraform plan
$ Terraform apply
```

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| route53_domain | name of new hosted zone | string | - | yes |


### Outputs

| Name | Description |
|------|-------------|
| name_servers | Name Servers of new Hosted Zone |
| zone_id | AWS Zone ID of new Hosted Zone |


Add the name servers for the created subdomain to the parent domain within the parent MOJ AWS account.

For more information [click here](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingNewSubdomain.html) for the AWS offical documentation 
