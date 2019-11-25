#!/bin/bash -x

set -euo pipefail

# Edit this to specify the cluster to destroy
CLUSTER=mourad-rds

main() {
  terraform_components
  kops_cluster
  terraform_base
  terraform_workspaces
}

terraform_components() {
  kops export kubecfg ${CLUSTER}.cloud-platform.service.justice.gov.uk
  (
    cd terraform/cloud-platform-components
    terraform12 init
    terraform12 workspace select ${CLUSTER}
    # prometheus_operator often fails to delete cleanly if anything has
    # happened to the open policy agent beforehand. Delete it first to
    # avoid any issues
    terraform12 destroy -target helm_release.prometheus_operator -auto-approve
    terraform12 destroy -auto-approve
  )
}

kops_cluster() {
  kops delete cluster --name ${CLUSTER}.cloud-platform.service.justice.gov.uk --yes
}

terraform_base() {
  (
    cd terraform/cloud-platform
    terraform12 init
    terraform12 workspace select ${CLUSTER}
    terraform12 destroy -auto-approve
  )
}

terraform_workspaces() {
  for dir in terraform/cloud-platform terraform/cloud-platform-components; do
    (
      cd ${dir}
      terraform12 workspace select default
      terraform12 workspace delete ${CLUSTER}
    )
  done
}

main
