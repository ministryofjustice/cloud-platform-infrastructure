#!/bin/bash

CLUSTER_DOMAIN=`terraform output cluster_domain_name`
if [ -z "$CLUSTER_DOMAIN" ]; then exit 1; fi
mkdir .key/ && chmod 700 .key/ || exit 1
echo -e  'y\n' | ssh-keygen -t rsa -f .key/"$CLUSTER_DOMAIN"_kops_id_rsa -N '' -C "$CLUSTER_DOMAIN" && chmod 600 .key/"$CLUSTER_DOMAIN"_kops_id_rsa
