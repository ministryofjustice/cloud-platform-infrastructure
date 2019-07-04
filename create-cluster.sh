#!/bin/bash

# See example.env.create-cluster for the environment variables
# which must be set before running this script.
#
# Usage:
#
#   ./create-cluster.sh [cluster-name]
#

readonly MAX_CLUSTER_NAME_LENGTH=12
readonly CLUSTER_SUFFIX=cloud-platform.service.justice.gov.uk
# TODO: use the right dns flush command, depending on the architecture of the local machine
readonly DNS_FLUSH_COMMAND='sudo killall -HUP mDNSResponder' # Mac OSX Mojave
readonly ELASTICSEARCH_ENABLED=false

set -euo pipefail

main() {
  local readonly cluster_name=$1

  check_prerequisites ${cluster_name}

  git-crypt unlock
  get_sudo

  create_cluster ${cluster_name}
  run_kops ${cluster_name}
  install_components ${cluster_name}

  kubectl cluster-info
}

create_cluster() {
  local readonly cluster_name=$1
  (
    cd terraform/cloud-platform
    rm -rf .terraform
    switch_terraform_workspace ${cluster_name}
    terraform apply -auto-approve
  )
}

run_kops() {
  local readonly cluster_name=$1

  kops create -f kops/${cluster_name}.yaml

  # This is a throwaway SSH key which we never need again.
  rm -f /tmp/${cluster_name} /tmp/${cluster_name}.pub
  ssh-keygen -b 4096 -P '' -f /tmp/${cluster_name}

  kops create secret --name ${cluster_name}.${CLUSTER_SUFFIX} sshpublickey admin -i /tmp/${cluster_name}.pub
  kops update cluster ${cluster_name}.${CLUSTER_SUFFIX} --yes --alsologtostderr

  wait_for_kops_validate
}

# TODO: figure out this problem, and fix it.
# For some reason, the first terraform apply sometimes fails with an error "could not find a ready tiller pod"
# This seems to be quite misleading, since adding a delay after 'helm init' makes no difference.
# A second run of the terraform apply usually works correctly.
install_components() {
  local readonly cluster_name=$1
  cd terraform/cloud-platform-components
  rm -rf .terraform
  switch_terraform_workspace ${cluster_name}

  # Ensure we have the latest helm charts for all the required components
  helm repo update
  # Without this step, you may get errors like this:
  #
  #     helm_release.open-policy-agent: chart “opa” matching 1.3.2 not found in stable index. (try ‘helm repo update’). No chart version found for opa-1.3.2
  #

  if terraform apply -auto-approve -var "elasticsearch_enabled=$ELASTICSEARCH_ENABLED"

  then
    echo "Cluster components installed."
  else
    echo "Initial components install reported errors. Sleeping and retrying..."
    sleep 120
    terraform apply -auto-approve -var "elasticsearch_enabled=$ELASTICSEARCH_ENABLED"
  fi
}

wait_for_kops_validate() {
  local readonly max_tries=30
  local validated=0

  for attempt in $(seq 1 $max_tries); do
    echo "Validate cluster, attempt ${attempt} of $max_tries..."

    if kops validate cluster
    then
      echo "Cluster validated."
      validated=1
      break
    else
      echo "Flushing DNS and sleeping before retry..."
      ${DNS_FLUSH_COMMAND}
      sleep 60
    fi
  done

  if [ "${validated}" -eq 0 ]; then
    echo "Failed to validate cluster after $max_tries attempts."
    exit 1
  fi
}

switch_terraform_workspace() {
  local readonly name=$1
  terraform init
  # The workspace might already exist, so the workspace new is allowed to fail
  # but the workspace select must succeed
  terraform workspace new ${name} || true
  terraform workspace select ${name}
}

check_prerequisites() {
  local readonly cluster_name=$1

  check_env_vars
  check_software_installed
  check_aws_profiles
  check_name_length ${cluster_name}

  # TODO: check helm version is >= 2.11
}

check_env_vars() {
  test $AWS_PROFILE
  test $AUTH0_DOMAIN
  test $AUTH0_CLIENT_ID
  test $AUTH0_CLIENT_SECRET
  test $KOPS_STATE_STORE
}

# https://stackoverflow.com/a/677212/794111 <-- explains 'hash' vs. 'which'
check_software_installed() {
  hash git-crypt
  hash terraform
  hash helm
  hash aws
  hash kops
  check_terraform_auth0
}

check_terraform_auth0() {
  if (find ~/.terraform.d/plugins/ | grep -q auth0)
  then
    true
  else
    echo "Terraform auth0 provider plugin not found."
    exit 1
  fi
}

# cluster is built in moj-cp, but cert-manager and external-dns need
# credentials for moj-dsd
check_aws_profiles() {
  for profile in moj-cp moj-dsd; do
    if grep -q "\[${profile}\]" ~/.aws/credentials
    then
      true
    else
      echo "AWS Profile '${profile}' not found."
      exit 1
    fi
  done
}

check_name_length() {
  local readonly cluster_name=$1
  local readonly length=${#cluster_name}
  if [ $length -gt 12 ]
  then
    echo "Cluster name '${cluster_name}' too long (${length} chars). Max. is ${MAX_CLUSTER_NAME_LENGTH}."
    exit 1
  fi
}

get_sudo() {
  echo
  echo "This script requires sudo, in order to flush your local DNS cache later."
  echo "Without this, 'kops validate cluster' will always fail."
  sudo true
}

main $1
