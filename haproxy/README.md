# Weighted load balancer using haproxy and ELB
Edit `variables.tf` and `terraform apply`

## Debugging
Using the key and IPs from `terraform output`, SSH as `ubuntu` and `echo "show errors" | socat unix-connect:/run/haproxy/admin.sock stdio`
