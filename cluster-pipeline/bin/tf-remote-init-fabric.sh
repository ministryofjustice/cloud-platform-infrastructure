#!/usr/bin/env bash

terraform remote config \
  -backend=s3 \
  -backend-config="bucket=$(terraform output terraform_state_store_bucket | tr -d '\n')" \
  -backend-config="key=$(terraform output kubernetes_fqdn | tr -d '\n').tfstate"

terraform remote push
