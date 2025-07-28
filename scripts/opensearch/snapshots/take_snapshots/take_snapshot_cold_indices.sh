#!/bin/bash

set -eu

IS_PIPELINE=$1

if [[ "$IS_PIPELINE" = true ]]; then
  export USE_SESSION_TOKEN=false
else
  export USE_SESSION_TOKEN=true
fi

LIVE_OS_ENDPOINT="https://app-logs.cloud-platform.service.justice.gov.uk"
SNAPSHOT_REPO="cp-live-app-logs-snapshot-s3-repository"
S3_SOURCE_INDEX_FILE="s3://cloud-platform-concourse-environments-live-reports/opensearch-snapshots/source-index-list.txt"

LOCAL_INDEX_FILE="index_list.txt"
TMP_FILE="$(mktemp)"
MAX_BATCH=10
COUNT=0

echo "Downloading index list from $S3_SOURCE_INDEX_FILE"
aws s3 cp "$S3_SOURCE_INDEX_FILE" "$LOCAL_INDEX_FILE"

# Function to check snapshot status
wait_for_snapshot() {
  local snapshot_name="$1"

  while true; do
    STATUS=$(curl -s -XGET -L \
      --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
      ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
      --aws-sigv4 "aws:amz:eu-west-2:es" \
      "${LIVE_OS_ENDPOINT}/_snapshot/${SNAPSHOT_REPO}/${snapshot_name}/_status" \
      | jq -r '.snapshots[0].state')

    if [[ "$STATUS" == "SUCCESS" ]]; then
      echo "Snapshot '${snapshot_name}' completed successfully."
      return 0
    elif [[ "$STATUS" == "FAILED" || "$STATUS" == "PARTIAL" ]]; then
      echo "Snapshot '${snapshot_name}' failed with status: $STATUS"
      return 1
    else
      echo "Snapshot '${snapshot_name}' is in progress... (status: $STATUS)"
      sleep 60
    fi
  done
}

echo "Reading index list from $LOCAL_INDEX_FILE"

while IFS= read -r index || [[ -n "$index" ]]; do
  index="${index//$'\r'/}"  # Strip Windows line endings

  if [[ -z "$index" || "$index" =~ ^# || "$index" =~ ^snapshot-taken- ]]; then
    echo "$index" >> "$TMP_FILE"
    continue
  fi

  if (( COUNT >= MAX_BATCH )); then
    echo "$index" >> "$TMP_FILE"
    continue
  fi

  echo "Migrating cold index $index to warm..."

  curl -s -XPOST -L \
    --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
    ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
    -H "Content-Type: application/json" \
    --aws-sigv4 "aws:amz:eu-west-2:es" \
    "${LIVE_OS_ENDPOINT}/_cold/migration/_warm" \
    -d "{
      \"indices\": \"${index}\"
    }"

  sleep 10
  echo
  echo "Taking snapshot of index: $index..."

  curl -s -XPUT -L \
    --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
    ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
    -H "Content-Type: application/json" \
    --aws-sigv4 "aws:amz:eu-west-2:es" \
    "${LIVE_OS_ENDPOINT}/_snapshot/${SNAPSHOT_REPO}/${index}" \
    -d "{
      \"indices\": \"${index}\",
      \"include_global_state\": false,
      \"partial\": false
    }"

  echo
  if wait_for_snapshot "$index"; then
    echo "snapshot-taken-$index" >> "$TMP_FILE"
  else
    echo "$index" >> "$TMP_FILE"
  fi

  COUNT=$((COUNT + 1))

  echo "Migrating warm index $index to cold..."

  curl -s -XPOST -L \
    --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
    ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
    -H "Content-Type: application/json" \
    --aws-sigv4 "aws:amz:eu-west-2:es" \
    "${LIVE_OS_ENDPOINT}/_ultrawarm/migration/${index}/_cold" \
    -d '{
      "timestamp_field": "@timestamp"
    }'

  sleep 10
  echo
  echo "Job completed for index $index"
done < "$LOCAL_INDEX_FILE"

echo "Uploading updated index list to $S3_SOURCE_INDEX_FILE"
mv "$TMP_FILE" "$LOCAL_INDEX_FILE"
aws s3 cp "$LOCAL_INDEX_FILE" "$S3_SOURCE_INDEX_FILE"

echo "Batch complete. $COUNT index snapshots taken."

TOTAL_INDEXES=$(wc -l < "$LOCAL_INDEX_FILE")
TOTAL_SNAPSHOT_TAKEN=$(grep -c '^snapshot-taken-' "$LOCAL_INDEX_FILE")

echo "Snapshot progress: $TOTAL_SNAPSHOT_TAKEN / $TOTAL_INDEXES indices completed."