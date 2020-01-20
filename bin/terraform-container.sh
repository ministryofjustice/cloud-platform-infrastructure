#!/bin/bash

set -euo pipefail

main() {
  check_prerequisites
  run_docker_container
}

check_prerequisites() {
  check_env_vars
  check_aws_profiles
  check_ssh_keys
}

check_env_vars() {
  test $AUTH0_DOMAIN
  test $AUTH0_CLIENT_ID
  test $AUTH0_CLIENT_SECRET
  test $CLUSTER_NAME
}

check_aws_profiles() {
  for profile in moj-cp moj-pi moj-dsd; do
    aws configure --profile ${profile} list > /dev/null || die "Missing AWS profile; ${profile}"
  done
}

check_ssh_keys() {
  local readonly key=${HOME}/.ssh/${CLUSTER_NAME}
  for file in ${key} ${key}.pub; do
    [ -f ${file} ] || die "File not found: ${file}"
  done
}

run_docker_container() {
  local readonly key=${HOME}/.ssh/${CLUSTER_NAME}

  docker run \
   -v $(pwd)/terraform:/opt/terraform \
   -v ${HOME}/.aws/credentials:/root/.aws/credentials \
   -v ${key}:/root/.ssh/id_rsa \
   -v ${key}.pub:/root/.ssh/id_rsa.pub \
   -e AUTH0_CLIENT_ID=${AUTH0_CLIENT_ID} \
   -e AUTH0_CLIENT_SECRET=${AUTH0_CLIENT_SECRET} \
   -e AUTH0_TENANT_DOMAIN=${AUTH0_DOMAIN} \
   -e CLUSTER_NAME=${CLUSTER_NAME} \
   -e AWS_PROFILE=moj-pi \
   -it 926803513772.dkr.ecr.eu-west-1.amazonaws.com/cloud-platform/infrastructure-image:latest bash
}

die() { echo "$*" 1>&2 ; exit 1; }

main
