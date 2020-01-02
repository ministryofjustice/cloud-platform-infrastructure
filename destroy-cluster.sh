#!/bin/bash -x

set -euo pipefail

# Edit this to specify the cluster to destroy
CLUSTER=david-test4
VPC_NAME=david-test3

main() {
  terraform_components
  kops_cluster
  terraform_base
  terraform_workspaces
  # terraform_vpc # Un comment to destroy the VPC
}

terraform_components() {
  kops export kubecfg ${CLUSTER}.cloud-platform.service.justice.gov.uk
  (
    cd terraform/cloud-platform-components
    terraform init
    terraform workspace select ${CLUSTER}
    # prometheus_operator often fails to delete cleanly if anything has
    # happened to the open policy agent beforehand. Delete it first to
    # avoid any issues
    terraform destroy -target helm_release.prometheus_operator -auto-approve
    terraform destroy -auto-approve
  )
}

kops_cluster() {
  kops delete cluster --name ${CLUSTER}.cloud-platform.service.justice.gov.uk --yes
}

terraform_base() {
  (
    cd terraform/cloud-platform
    terraform init
    terraform workspace select ${CLUSTER}
    local readonly vpc_name="${VPC_NAME:-${CLUSTER}}"
    terraform destroy -var vpc_name="${vpc_name}" -auto-approve
  )
}

terraform_vpc() {
  (
    cd terraform/cloud-platform-network
    terraform init
    terraform workspace select ${VPC_NAME}
    terraform destroy -auto-approve
  )
}

terraform_workspaces() {
  for dir in terraform/cloud-platform terraform/cloud-platform-components; do
    (
      cd ${dir}
      terraform workspace select default
      terraform workspace delete ${CLUSTER}
    )
  done
}

main
