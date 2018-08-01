#!/bin/bash

if [ $# -eq 1 ];
then
  workspace="$1"
  echo 'creating terraform resources'
  ../../bin/01-terraform_resources.sh "$workspace" || exit 1
  echo 'creating cluster config from terraform outputs'
  ../../bin/03-cluster_config.py ../../kops/"$workspace".yaml > ~/clusterspec.yaml || exit 1
  echo 'creating cluster'
  ../../bin/04-kops_elements.sh ~/clusterspec.yaml || exit 1

else
  echo "usage: $0 <cluster-name>"
fi
