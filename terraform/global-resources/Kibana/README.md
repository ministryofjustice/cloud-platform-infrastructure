This will deploy three AWS-managed ES domains (test, live and audit), with Kibana on a public IP and and access policy allowing only the k8s clusters (and the OIDc proxy that will be running on them)
To redeploy, just `terraform plan && terraform apply`
