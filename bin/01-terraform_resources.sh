#!/bin/bash

if [ $# -eq 1 ];
then
  workspace="$1"
  terraform init || exit 1
  terraform refresh || exit 1
  terraform workspace new "$workspace" || terraform workspace select "$workspace" || exit 1
  terraform plan -out ~/plan.out || exit 1
  terraform show ~/plan.out || exit 1
  terraform apply ~/plan.out || exit 1
else
  echo "usage: $0 <cluster-name>"
fi
