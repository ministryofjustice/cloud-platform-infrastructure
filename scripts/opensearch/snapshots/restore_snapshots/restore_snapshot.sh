#!/bin/bash

set -eu

IS_PIPELINE=$1

if [[ "$IS_PIPELINE" = true ]]; then
  export USE_SESSION_TOKEN=false
else
  export USE_SESSION_TOKEN=true
fi

RESTORE_OS_ENDPOINT="https://search-test-restore-5utyz7htozji7omw54emmciqum.eu-west-2.es.amazonaws.com"
SNAPSHOT_REPO="cp-live-app-logs-snapshot-s3-repository"
S3_SOURCE_INDEX_FILE="s3://cloud-platform-concourse-environments-live-reports/opensearch-snapshots/source-index-list.txt"
S3_RESTORED_INDEX_FILE="s3://cloud-platform-concourse-environments-live-reports/opensearch-snapshots/snapshot-restored.txt"

MAX_BATCH=10
TMP_FILE="$(mktemp)"
RESTORED_INDICES_FILE="$(mktemp)"
EXISTING_RESTORED_FILE="$(mktemp)"

echo "Downloading index list from $S3_SOURCE_INDEX_FILE"
aws s3 cp "$S3_SOURCE_INDEX_FILE" "$TMP_FILE"
TOTAL_INDICES_TO_RESTORE=$(wc -l < "$TMP_FILE")
aws s3 cp "$S3_RESTORED_INDEX_FILE" "$EXISTING_RESTORED_FILE"

COUNT=0

wait_for_restore() {
  local index_name="$1"
  echo "Waiting for restore to complete for index: $index_name"

  while true; do
    local recovery_output
    recovery_output=$(curl -s -XGET -L \
      --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
      ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
      --aws-sigv4 "aws:amz:eu-west-2:es" \
      "$RESTORE_OS_ENDPOINT/${index_name}/_recovery")

    local shard_count
    shard_count=$(echo "$recovery_output" | jq -r ".\"${index_name}\".shards | length")
    echo "Checking $shard_count shards for index: $index_name"

    local ready_snapshot_shards=0

    for ((i = 0; i < shard_count; i++)); do
      local type stage percent

      type=$(echo "$recovery_output" | jq -r ".\"${index_name}\".shards[$i].type")
      stage=$(echo "$recovery_output" | jq -r ".\"${index_name}\".shards[$i].stage")
      percent=$(echo "$recovery_output" | jq -r ".\"${index_name}\".shards[$i].index.size.percent")

      echo "Shard $i — type=$type, stage=$stage, percent=$percent"

      if [[ "$type" == "SNAPSHOT" && "$stage" == "DONE" && "$percent" == "100.0%" ]]; then
        (( ++ready_snapshot_shards ))
      fi
    done

    total_snapshot_shards=$(echo "$recovery_output" | jq -r ".\"${index_name}\".shards | map(select(.type == \"SNAPSHOT\")) | length")    
    
    echo "Ready: $ready_snapshot_shards / Total: $total_snapshot_shards"

    if (( ready_snapshot_shards == total_snapshot_shards )); then
      echo "Restore completed for index: $index_name"
      return 0
    else
      echo "Waiting for restore to complete..."
      sleep 60
    fi
  done
}

while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  if [[ "$line" == snapshot-taken-* ]]; then
    raw_index_name="${line#snapshot-taken-}"
    echo "Processing index: $raw_index_name"

    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -I -L \
      --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
      ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
      --aws-sigv4 "aws:amz:eu-west-2:es" \
      "$RESTORE_OS_ENDPOINT/${raw_index_name}")

    if [[ "$STATUS_CODE" == "200" ]]; then
      echo "Index $raw_index_name already exists in this OpenSearch cluster. Skipping."
      continue
    fi

    echo "Index $raw_index_name does not exist in this OpenSearch cluster. Restoring..."

    # Restore snapshot
    curl -s -XPOST -L \
      --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
      ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
      -H "Content-Type: application/json" \
      --aws-sigv4 "aws:amz:eu-west-2:es" \
      "$RESTORE_OS_ENDPOINT/_snapshot/$SNAPSHOT_REPO/$raw_index_name/_restore" \
      -d "{
        \"indices\": \"$raw_index_name\",
        \"include_global_state\": false,
        \"partial\": false,
        \"ignore_unavailable\": false,
        \"include_aliases\": false
      }"

    echo
    echo "Setting replicas to 0 for $raw_index_name..."
    curl -s -XPUT -L \
      --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
      ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
      -H "Content-Type: application/json" \
      --aws-sigv4 "aws:amz:eu-west-2:es" \
      "$RESTORE_OS_ENDPOINT/$raw_index_name/_settings" \
      -d '{
        "index": {
          "number_of_replicas": 0
        }
      }'

    wait_for_restore "$raw_index_name"

    echo "Checking if index $raw_index_name is green..."

    while true; do
        index_health=$(curl -s -XGET -L \
            --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
            ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"}  \
            --aws-sigv4 "aws:amz:eu-west-2:es" \
            "$RESTORE_OS_ENDPOINT/_cat/indices/$raw_index_name?h=health")

        if [[ "$index_health" == "green" ]]; then
            echo "Index $raw_index_name is green. Proceeding to migrate to warm tier."
            break
        else
            echo "Index $raw_index_name health is $index_health. Sleeping 60s and retrying..."
            sleep 10
        fi
    done

    echo "Migrating $raw_index_name to warm tier..."
    curl -s -XPOST -L \
      --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
      ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
      --aws-sigv4 "aws:amz:eu-west-2:es" \
      "$RESTORE_OS_ENDPOINT/_ultrawarm/migration/$raw_index_name/_warm"

    echo
    echo "$raw_index_name" >> "$RESTORED_INDICES_FILE"

    COUNT=$((COUNT + 1))
    if [[ "$COUNT" -ge "$MAX_BATCH" ]]; then
      echo "Reached max batch size of $MAX_BATCH. Stopping."
      break
    fi
  else
    echo "Skipping non-taken snapshot line: $line"
  fi
done < "$TMP_FILE"

# Append newly restored indices to existing list and upload to S3
cat "$RESTORED_INDICES_FILE" >> "$EXISTING_RESTORED_FILE"
aws s3 cp "$EXISTING_RESTORED_FILE" "$S3_RESTORED_INDEX_FILE"

echo "Batch complete. $COUNT index snapshots restored."

TOTAL_RESTORED_INDICES=$(wc -l < "$EXISTING_RESTORED_FILE")

echo "Total restored snapshot: $TOTAL_RESTORED_INDICES / $TOTAL_INDICES_TO_RESTORE"