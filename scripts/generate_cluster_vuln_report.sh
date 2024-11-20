#!/bin/bash

set -eu

CLUSTER_NAME=$1
FILENAME=$(date -I)

update_obj() {
    NS_OBJ=$(cat $1)

    NS=$(echo $NS_OBJ | jq -r '.metadata.namespace')

    ANNOTATIONS=$(jq -r '.metadata.annotations' "$NS.json")

    SOURCE_CODE=$(echo $ANNOTATIONS | jq -r '."cloud-platform.justice.gov.uk/source-code"')
    OWNER=$(echo $ANNOTATIONS | jq -r '."cloud-platform.justice.gov.uk/owner"')
    TEAM_NAME=$(echo $ANNOTATIONS | jq -r '."cloud-platform.justice.gov.uk/team-name"')
    # add the new values to the object
    UPDATED_SOURCE=$(echo $NS_OBJ | jq --arg SOURCE_CODE "$SOURCE_CODE" '.metadata += {"cloud-platform.justice.gov.uk/source-code": $SOURCE_CODE }')

    UPDATED_OWNER=$(echo $UPDATED_SOURCE | jq --arg OWNER "$OWNER" '.metadata += {"cloud-platform.justice.gov.uk/owner": $OWNER }')

    UPDATED_OBJ=$(echo $UPDATED_OWNER | jq --arg TEAM_NAME "$TEAM_NAME" '.metadata += {"cloud-platform.justice.gov.uk/team-name": $TEAM_NAME }')

    echo $UPDATED_OBJ
}

echo "Getting all vulnerabilities for ${CLUSTER_NAME}..."
kubectl get vulnerabilityreports.aquasecurity.github.io -A -o json > ${CLUSTER_NAME}_vuln.json

echo "Getting namespace annotations to enrich vulnerability report..."
jq -r '.items | map(.metadata.namespace) | unique | .[]' ${CLUSTER_NAME}_vuln.json | xargs -n 1 | xargs -I % bash -c 'kubectl get ns % -ojson > %.json'

echo "Looping over vulnerabilities and enriching with relevant namespace details..."
# split json items onto a newline so parallel can loop over them
jq -c '.items | .[]' ${CLUSTER_NAME}_vuln.json > item_per_line

export -f update_obj

# now run script to enrich namespace data on each item -- this is much quicker than a bash loop
parallel -a item_per_line --recend '}\n' --line-buffer --pipe-part --will-cite --block 1K "update_obj {}" > updated_objects

# create the json array
sed '1s/^/[/; $!s/$/,/; $s/$/]/' updated_objects > out.json

# use the new json array and create new json report
/bin/cat out.json | jq -c '{ items: .}' > "${FILENAME}.json"

echo "Vulnerability data enriched."

echo "Pushing report to s3..."
# https://github.com/ministryofjustice/cloud-platform-environments/blob/main/namespaces/live.cloud-platform.service.justice.gov.uk/moj-vuln-report/resources/s3.tf
aws s3 cp "${FILENAME}.json" s3://cloud-platform-vulnerability-reports/$CLUSTER_NAME/

exit 0

