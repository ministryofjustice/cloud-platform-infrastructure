#!/bin/bash

delete_pods() {
  NAMESPACE=$(echo "$1" | sed -E 's/\/api\/v1\/namespaces\/(.*)\/pods\/.*/\1/')
  POD=$(echo "$1" | sed -E 's/.*\/pods\/(.*)\/eviction/\1/')

  echo $NAMESPACE

  echo $POD

  kubectl delete pod -n $NAMESPACE $POD
}

export -f delete_pods

TIME_NOW_EPOCH=$(date +%s)

START_TIME=$(($TIME_NOW_EPOCH - 180))

CLUSTER_LOG_GROUP=$1

QUERY_ID=$(aws logs start-query \
  --start-time $START_TIME \
  --end-time $TIME_NOW_EPOCH \
  --log-group-name $CLUSTER_LOG_GROUP \
  --query-string 'fields @timestamp, @message | filter @logStream like "kube-apiserver-audit" | filter ispresent(requestURI) | filter objectRef.subresource = "eviction" | filter responseObject.status = "Failure" | display @logStream, requestURI, responseObject.message | stats count(*) as retry by requestURI, requestObject.message' \
  | jq -r '.queryId' )

sleep 2

RESULTS=$(aws logs get-query-results --query-id $QUERY_ID)

echo -n $RESULTS | jq '.results[]' | grep '/api/v1' | awk '{ print $2 }' | xargs -I {} bash -c 'delete_pods {}'

exit 0