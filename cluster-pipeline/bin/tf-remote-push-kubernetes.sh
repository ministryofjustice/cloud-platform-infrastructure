#!/usr/bin/env bash

cd kubernetes/
terraform remote config \
  -backend=s3 \
  -backend-config="bucket=$(terraform output terraform_state_store_bucket | tr -d '\n')" \
  -backend-config="key=$(terraform output kubernetes_fqdn | tr -d '\n')-kubernetes.tfstate"

terraform remote push
