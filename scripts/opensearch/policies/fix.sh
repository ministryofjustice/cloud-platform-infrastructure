#!/bin/bash

set -u

IS_PIPELINE=$1


if [[ "$IS_PIPELINE" = true ]]; then
    export USE_SESSION_TOKEN=false
else
    export USE_SESSION_TOKEN=true
fi

HOT_INDICES="$(curl -L --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_hot" | awk '{ print $3 }' | grep -v '^\.' | grep -v "reindex")"


WARM_INDICES="$(curl -L --silent --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_warm" | awk '{ print $3 }' | grep -v '^\.' | grep -v "reindex")"

for i in ${HOT_INDICES} ${WARM_INDICES}
do
    IS_MANAGED=$(curl -L --silent --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_plugins/_ism/explain/$i" | jq '.total_managed_indices')

    if [ "$IS_MANAGED" -eq 0 ]; then
        curl -X POST -L --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" -H "Content-Type: application/json" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_plugins/_ism/add/$i" -d '{ "policy_id": "hot-warm-cold-delete" }'
    fi
done

exit 0
