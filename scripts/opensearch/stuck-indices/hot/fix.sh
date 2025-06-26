#!/bin/bash

set -u

BATCH_SIZE=15

TODAY="$(date +'%Y.%m.%d')"
IS_PIPELINE=$1

if [[ "$IS_PIPELINE" = true ]]; then
    USE_SESSION_TOKEN=false
else
    USE_SESSION_TOKEN=true
fi

CURRENT_NUM_REINDEXING="$(curl -L --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_tasks" | jq '.nodes | to_entries[].value.tasks[] | .action' | grep reindex | wc -l)"

HOT_INDICES="$(curl -L --silent --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_hot" | awk '{ print $3 }' | sort)"

WARM_INDICES="$(curl -L --silent --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_warm" | awk '{ print $3 }' | sort)"

if [ "$CURRENT_NUM_REINDEXING"  -gt 0 ]; then
    echo "There are tasks currently reindexing..."
    exit 0
fi

for i in ${HOT_INDICES}
do
    if (echo "$WARM_INDICES" | grep -q "$i-reindexed"); then
        printf "\n\n"
        echo "deleting old index as it has already been reindexed and moved to warm: $i"
        printf "\n\n"
        curl -X DELETE -L --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/$i"
    fi
done

echo "selecting new indices to reindex..."

ISM_POLICY_STATE_JSON=$(curl -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY  ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_plugins/_ism/explain/_all)

RESTRUCTURED_JSON=$(echo $ISM_POLICY_STATE_JSON | jq '[.[] | {index: .index?, state: .action?.failed?, cause: .info?.cause?, message: .info?.message?}]')

echo $RESTRUCTURED_JSON

WARM_INDEXES=$(echo $RESTRUCTURED_JSON | jq '[.[] | select(.cause != null) | select(.cause? | contains("exceeds the warm migration shard size limit")) | select(.index)]' | jq --argjson BATCH_SIZE "$BATCH_SIZE" '.[:$BATCH_SIZE]')

INDICES_TO_REINDEX="$(curl -L --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_hot?s=pri.store.size:desc" | awk '{ print $3 " " $10 }'  | grep -v '^\.' | grep -v $TODAY | grep -v "reindex")"

echo $WARM_INDEXES | jq -c '.[]' | while read i;
do
    TARGET_INDEX=$(echo $i | jq -r '.index')

    LINE=$(echo "$INDICES_TO_REINDEX" | grep "$TARGET_INDEX")
    SIZE=$(echo "$LINE" | awk '{ print $2 }')
    INDEX=$(echo "$LINE" | awk '{ print $1 }')
    SHARD_NUMB=15
    if [[ $SIZE =~ "tb" ]]; then
        STRIPED_SIZE=${SIZE%tb}
        SHARD_NUMB="$(echo "$STRIPED_SIZE * 10" | bc -l | sed -e 's/\..*//g')"
    fi

    curl -X PUT -H "Content-Type: application/json" -L --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/$INDEX-reindexed" -d "{\"settings\": {\"index\": {\"number_of_shards\": $SHARD_NUMB }}}"

    sleep 0.2

    curl -L -X POST -H "Content-Type: application/json" --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_reindex" -d "{\"source\": {\"index\": \"$INDEX\"}, \"dest\": {\"index\": \"$INDEX-reindexed\"}}" --max-time 10
done

echo "${BATCH_SIZE} indices are now reindexing..."
exit 0

