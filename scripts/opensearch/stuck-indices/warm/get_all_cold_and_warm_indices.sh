#!/bin/bash

set -eu
set -o pipefail

USE_SESSION_TOKEN=$1
PAGE_ID=0
INDEX_LENGTH=99
COUNTER=0

touch cold_indices_json/random.json
rm cold_indices_json/*json


if [ $PAGE_ID -eq 0 ]; then
    RESP=$(curl -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY  ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_cold/indices/_search | jq '.')
    PAGE_ID=$(echo "$RESP" | jq -r '. | .pagination_id')
    echo "$RESP" > "cold_indices_json/$COUNTER.json"
    COUNTER=$((COUNTER+1))

fi

while [ -n "$PAGE_ID" ] || [ $PAGE_ID != null ] && [ $INDEX_LENGTH -ne 0 ];
do
    RESP=$(curl -L -H "Content-Type: application/json" --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_cold/indices/_search -d '{ "pagination_id": "'$PAGE_ID'" }' | jq '.')
    PAGE_ID=$(echo "$RESP" | jq -r '. | .pagination_id')
    echo "$RESP" > "cold_indices_json/$COUNTER.json"
    INDEX_LENGTH=$(echo $RESP | jq '. | .indices | length')

    sleep 0.3
    COUNTER=$((COUNTER+1))
done

jq -s '.[0].indices=([.[].indices] | flatten) | .[0]' cold_indices_json/*json > collated_cold_indices

curl -L -H "Content-Type: application/json" --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_warm?v" | awk '{ print $3 " " $7 }' > all_warm_indices

exit 0

