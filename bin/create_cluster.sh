#!/bin/bash

if [ $# -eq 1 ];
then
  workspace="$1"
  terraform init
  terraform workspace new "$workspace"
  terraform plan -out plan.out
  terraform show plan.out
  terraform apply plan.out

  KOPS_STATE_STORE=`terraform output kops_state_store`                                                                                                         
  CLUSTER_DOMAIN=`terraform output cluster_domain_name`
  mkdir ~/key/ && chmod 700 ~/key/
  ssh-keygen -t rsa -f ~/key/"$CLUSTER_DOMAIN"_kops_id_rsa -N '' -C "$CLUSTER_DOMAIN" && chmod 600 ~/key/"$CLUSTER_DOMAIN"_kops_id_rsa
  python ../../bin/create_cluster_config.py ../../kops/"$workspace".yaml > ~/clusterspec.yaml
  cat ~/clusterspec.yaml
  kops create -f ~/clusterspec.yaml --state="s3://$KOPS_STATE_STORE" || exit 1
  kops create secret --name "$CLUSTER_DOMAIN" --state="s3://$KOPS_STATE_STORE" sshpublickey admin -i ~/key/"$CLUSTER_DOMAIN"_kops_id_rsa.pub
  aws s3 cp ~/clusterspec.yaml "s3://$KOPS_STATE_STORE/$CLUSTER_DOMAIN"
  until `kops update cluster "$CLUSTER_DOMAIN"  --yes --state="s3://$KOPS_STATE_STORE"`; do echo "Try again"; done
  kops validate cluster --state="s3://$KOPS_STATE_STORE"
else
  echo "usage: $0 <cluster-name>"
fi
