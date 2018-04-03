#!/bin/bash

FABRIC_NAME=$1
DOMAIN_NAME=$2
FABRIC_REGION=$3

if [ $# -ne 3 ]
then
  echo "usage: $0 <FABRIC_NAME> <DOMAIN_NAME> <FABRIC_REGION>"
else
  echo "Creating config.json..."

  echo "
  {
      \"domain_name\": \""$DOMAIN_NAME"\",
      \"fabric_availability_zones\": [],
      \"fabric_name\": \""$FABRIC_NAME"\",
      \"fabric_region\": \""$FABRIC_REGION"\"
  }" > config.json && echo "Done."
fi
