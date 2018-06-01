#!/bin/bash

if [ $# -eq 1 ];
then
  KOPS_STATE_STORE=`terraform output kops_state_store` 
  if [ -z "$KOPS_STATE_STORE" ]; then exit 1; fi 
  CLUSTER_DOMAIN=`terraform output cluster_domain_name`
  if [ -z "$CLUSTER_DOMAIN" ]; then exit 1; fi
  kops create -f "$1" --state="s3://$KOPS_STATE_STORE" || exit 1
  kops create secret --name "$CLUSTER_DOMAIN" --state="s3://$KOPS_STATE_STORE" sshpublickey admin -i .key/"$CLUSTER_DOMAIN"_kops_id_rsa.pub || exit 1
  aws s3 cp "$1" "s3://$KOPS_STATE_STORE/$CLUSTER_DOMAIN" || exit 1

  rc=1; while [ "$rc" -eq 1 ]; do kops update cluster "$CLUSTER_DOMAIN"  --yes --state="s3://$KOPS_STATE_STORE"; rc="$?"; done
  rc=1; while [ "$rc" -eq 1 ]; do echo 'checking cluster'; kops validate cluster --state="s3://$KOPS_STATE_STORE"; rc="$?" ; sleep 60; done
else
  echo "usage: $0 <cluster-spec>"
fi
