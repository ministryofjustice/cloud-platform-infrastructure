# Weighted load balancer using haproxy and ALB
This will create AWS resources necessary to front arbitrary HTTP(S) servers. The stack is entirely self-contained in its own VPC, creating EC2 instances / SGs / ALB / ASG / Route53 entries / ACM SSL cert / installing HAproxy from the Ubuntu PPA.

## Usage
Edit `variables.tf` and `terraform apply`

## Debugging
Using the key and IPs from `terraform output`, SSH as `ubuntu` and `echo "show errors" | socat unix-connect:/run/haproxy/admin.sock stdio`

## Cleanup
`terraform destroy` will remove the VPC and all the linked resources

## How to update the weights in an orderly fashion

Assuming you're calling on this as a module,

1. You'll need the following information:

```
terraform output -module=haproxy
```

The ssh key can be useful, extract `ssh-private` into a file, let's call it `haproxy-key` and `chmod 600 haproxy-key`.

2. Remove first node from the target group, you can do this manually using the aws cli or the web console. This makes its status `draining`. Wait for it to finish draining connections (5 minutes) and disappear from the list of targets.

3. Target apply the changes:

```
terraform apply -var-file=prod.tfvars -target='module.haproxy.aws_instance.haproxy_node[0]' -target='module.haproxy.aws_lb_target_group_attachment.haproxy_nodes[0]'
```

4. Repeat step 2 for the other node and then target apply again:
```
terraform apply -var-file=prod.tfvars -target='module.haproxy.aws_instance.haproxy_node[1]' -target='module.haproxy.aws_lb_target_group_attachment.haproxy_nodes[1]'
```

Useful things to keep an eye on:
- Cloudwatch metrics for the ALB
- Cloudwatch metrics for the `haproxy` EC2 instances
- Prometheus ingress controller traffic for the namespace (eg. `sum(rate(nginx_ingress_controller_requests{exported_namespace="my_namespace"}[5m]))`)
- `haproxy` stats page (`ssh -L 9000:localhost:9000 -i haproxy-key ubuntu@<ip-address>`)

_tip: when searching for the AWS resources, it's easy to find them using the random id; in the output from step (1) you'll see something like `alb-dns = haproxy-alb-d8f2bc77-01234567.eu-west-1.elb.amazonaws.com`, the id is `d8f2bc77`._
