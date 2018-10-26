# Weighted load balancer using haproxy and ALB
This will create AWS resources necessary to front arbitrary HTTP(S) servers. The stack is entirely self-contained in its own VPC, creating EC2 instances / SGs / ALB / ASG / Route53 entries / ACM SSL cert / installing HAproxy from the Ubuntu PPA.

## Usage
Edit `variables.tf` and `terraform apply`

## Debugging
Using the key and IPs from `terraform output`, SSH as `ubuntu` and `echo "show errors" | socat unix-connect:/run/haproxy/admin.sock stdio`

## Cleanup
`terraform destroy` will remove the VPC and all the linked resources
