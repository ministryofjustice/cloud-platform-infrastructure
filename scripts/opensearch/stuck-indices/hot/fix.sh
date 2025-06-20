#!/bin/bash

set -u

BATCH_SIZE=10

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

INDICES_TO_REINDEX="$(curl -L --user "$AWS_ACCESS_KEY_ID":"$AWS_SECRET_ACCESS_KEY" ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_hot?s=pri.store.size:desc" | awk '{ print $3 " " $10 }'  | grep -v '^\.' | grep -v $TODAY | grep -v "reindex" | head -n $BATCH_SIZE)"

echo "$INDICES_TO_REINDEX" | while read -r line
do
    SIZE=$(echo "$line" | awk '{ print $2 }')
    INDEX=$(echo "$line" | awk '{ print $1 }')
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

