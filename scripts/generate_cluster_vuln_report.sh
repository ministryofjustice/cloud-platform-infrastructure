#!/bin/bash

set -eu

CLUSTER_NAME=$1
FILENAME=$(date -I)

echo "Getting all vulnerabilities for ${CLUSTER_NAME}..."
kubectl get vulnerabilityreports.aquasecurity.github.io -A -o json > ${CLUSTER_NAME}_vuln.json

echo "Getting namespace annotations to enrich vulnerability report..."
jq -r '.items | map(.metadata.namespace) | unique | .[]' ${CLUSTER_NAME}_vuln.json | xargs -n 1 | xargs -I % bash -c 'kubectl get ns % -ojson > %.json'

echo "Looping over vulnerabilities and enriching with relevant namespace details..."
# split json items onto a newline so parallel can loop over them
jq -c '.items | .[]' ${CLUSTER_NAME}_vuln.json > item_per_line

# now run script to enrich namespace data on each item -- this is much quicker than a bash loop
/bin/cat item_per_line | parallel --jobs 50% "./update_obj.sh {}" > updated_objects

# create the json array
sed '1s/^/[/; $!s/$/,/; $s/$/]/' updated_objects > out.json

# use the new json array and create new json report
/bin/cat out.json | jq -c '{ items: .}' > "${FILENAME}.json"

echo "Vulnerabilitiy data enriched."

echo "Pushing report to s3..."
# https://github.com/ministryofjustice/cloud-platform-environments/blob/6b8397d5de591c6f6f533750291117b2e78d4296/namespaces/live.cloud-platform.service.justice.gov.uk/moj-vuln-report/resources/s3.tf#L4
aws s3 cp "${FILENAME}.json" s3://cloud-platform-vulnerability-reports/$CLUSTER_NAME/

exit 0

