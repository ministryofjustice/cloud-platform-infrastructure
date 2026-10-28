#!/bin/bash
# Restore snapshots listed in S3 onto the restore domain. Stops on the first failure.
# EXTRACT_NAMESPACE set: copy that namespace into ${EXTRACT_PREFIX}<index>, check counts, delete the full index.
# Usage: ./restore_snapshot.sh <true|false>  Env: RESTORE_OS_ENDPOINT, EXTRACT_NAMESPACE, EXTRACT_PREFIX, MAX_BATCH, STEP_TIMEOUT_SECS

set -uo pipefail

IS_PIPELINE=${1:-}
[[ "$IS_PIPELINE" == true || "$IS_PIPELINE" == false ]] || { echo "usage: $0 <true|false>"; exit 1; }

RESTORE_OS_ENDPOINT=${RESTORE_OS_ENDPOINT:-https://silas-log-restore.cloud-platform.service.justice.gov.uk}
SNAPSHOT_REPO="cp-live-app-logs-snapshot-s3-repository"
S3_SOURCE_INDEX_FILE="s3://cloud-platform-concourse-environments-live-reports/opensearch-snapshots/source-index-list.txt"
S3_RESTORED_INDEX_FILE="s3://cloud-platform-concourse-environments-live-reports/opensearch-snapshots/snapshot-restored.txt"
EXTRACT_NAMESPACE=${EXTRACT_NAMESPACE:-}
EXTRACT_PREFIX=${EXTRACT_PREFIX:-silas150-extract-}
MAX_BATCH=${MAX_BATCH:-10}
STEP_TIMEOUT_SECS=${STEP_TIMEOUT_SECS:-7200}

TMP_FILE="$(mktemp)"
RESTORED_INDICES_FILE="$(mktemp)"
EXISTING_RESTORED_FILE="$(mktemp)"
COUNT=0

AUTH=(--user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" --aws-sigv4 "aws:amz:eu-west-2:es")
[[ "$IS_PIPELINE" != true ]] && AUTH+=(-H "x-amz-security-token: $AWS_SESSION_TOKEN")

die() { echo "FATAL: $*" >&2; exit 1; }

req() {
  local out
  out=$(curl -s -w $'\n%{http_code}' "${AUTH[@]}" "$@") || out=$'\n000'
  HTTP_CODE=${out##*$'\n'}
  BODY=${out%$'\n'*}
  [[ "$HTTP_CODE" == 401 || "$HTTP_CODE" == 403 ]] && die "HTTP $HTTP_CODE on $* - credentials expired, not permitted, or request signing failed"
  return 0
}

wait_until() {
  local what=$1 fn=$2 deadline=$(( $(date +%s) + STEP_TIMEOUT_SECS ))
  until "$fn"; do
    [[ $(date +%s) -ge $deadline ]] && { echo "  timed out waiting for: $what"; return 1; }
    sleep 30
  done
}

is_green() {
  req "$RESTORE_OS_ENDPOINT/_cluster/health/$INDEX"
  [[ "$HTTP_CODE" == 200 && $(jq -r '.status' <<<"$BODY") == green ]]
}

ns_query() { jq -nc --arg ns "$EXTRACT_NAMESPACE" '{term: {"kubernetes.namespace_name.keyword": $ns}}'; }

count_ns() { # count_ns <index> <query-json>
  req -H "Content-Type: application/json" "$RESTORE_OS_ENDPOINT/$1/_count" -d "{\"query\": $2}"
  [[ "$HTTP_CODE" == 200 ]] && jq -r '.count' <<<"$BODY" || echo "ERR"
}

# Task IDs contain ":", which curl --aws-sigv4 cannot sign in a path, so list running reindex tasks instead.
reindex_done() {
  req "$RESTORE_OS_ENDPOINT/_tasks?actions=*reindex&detailed=true"
  [[ "$HTTP_CODE" == 200 ]] || return 1
  [[ $(jq --arg d "$DEST" '[.nodes[].tasks[] | select(.description | contains("to [" + $d + "]"))] | length' <<<"$BODY") == 0 ]]
}

finish_extract() {
  local src_count dest_count
  src_count=$(count_ns "$INDEX" "$(ns_query)")
  [[ "$src_count" =~ ^[0-9]+$ ]] || { echo "  !! cannot count source"; return 1; }
  req -XPOST "$RESTORE_OS_ENDPOINT/$DEST/_refresh"
  dest_count=$(count_ns "$DEST" '{"match_all": {}}')
  if [[ "$dest_count" != "$src_count" ]]; then
    echo "  !! count mismatch: source $src_count, $DEST $dest_count - keeping $INDEX for investigation"
    return 1
  fi
  echo "  counts match ($dest_count); deleting restored full index $INDEX"
  req -XDELETE "$RESTORE_OS_ENDPOINT/$INDEX"
  [[ "$HTTP_CODE" == 200 ]] || { echo "  !! delete of $INDEX failed: HTTP $HTTP_CODE"; return 1; }
  echo "$INDEX $DEST $dest_count" >>"$RESTORED_INDICES_FILE"
}

extract() {
  local mapping
  req "$RESTORE_OS_ENDPOINT/$INDEX/_mapping"
  [[ "$HTTP_CODE" == 200 ]] || { echo "  !! cannot read mapping: HTTP $HTTP_CODE"; return 1; }
  mapping=$(jq -c --arg i "$INDEX" '.[$i].mappings' <<<"$BODY")
  req -XPUT -H "Content-Type: application/json" "$RESTORE_OS_ENDPOINT/$DEST" \
    -d "{\"settings\": {\"index\": {\"number_of_shards\": 1, \"number_of_replicas\": 0}}, \"mappings\": $mapping}"
  [[ "$HTTP_CODE" == 200 ]] || { echo "  !! cannot create $DEST: HTTP $HTTP_CODE $BODY"; return 1; }
  echo "  copying $EXTRACT_NAMESPACE documents from $INDEX to $DEST"

  req -XPOST -H "Content-Type: application/json" "$RESTORE_OS_ENDPOINT/_reindex?wait_for_completion=false&slices=auto" \
    -d "{\"source\": {\"index\": \"$INDEX\", \"query\": $(ns_query)}, \"dest\": {\"index\": \"$DEST\"}}"
  [[ -n "$(jq -r '.task // empty' <<<"$BODY")" ]] || { echo "  !! reindex not started: HTTP $HTTP_CODE $BODY"; return 1; }
  wait_until "reindex $INDEX -> $DEST" reindex_done || return 1
  finish_extract
}

echo "Restore endpoint: $RESTORE_OS_ENDPOINT${EXTRACT_NAMESPACE:+ (extract mode: $EXTRACT_NAMESPACE -> ${EXTRACT_PREFIX}*)}"
req "$RESTORE_OS_ENDPOINT/_cluster/health"
[[ "$HTTP_CODE" == 200 ]] || die "cannot reach $RESTORE_OS_ENDPOINT (HTTP $HTTP_CODE)"

aws s3 cp "$S3_SOURCE_INDEX_FILE" "$TMP_FILE" || die "cannot download $S3_SOURCE_INDEX_FILE"
TOTAL_INDICES_TO_RESTORE=$(grep -c '^snapshot-taken-' "$TMP_FILE")
aws s3 cp "$S3_RESTORED_INDEX_FILE" "$EXISTING_RESTORED_FILE" || : >"$EXISTING_RESTORED_FILE"

FAILED=""
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" == snapshot-taken-* ]] || continue
  INDEX="${line#snapshot-taken-}"
  awk -v i="$INDEX" '$1 == i {f = 1} END {exit !f}' "$EXISTING_RESTORED_FILE" && continue

  DEST="${EXTRACT_PREFIX}${INDEX}"
  if [[ -n "$EXTRACT_NAMESPACE" ]]; then
    req "$RESTORE_OS_ENDPOINT/$DEST/_settings"
    if [[ "$HTTP_CODE" == 200 ]]; then
      req "$RESTORE_OS_ENDPOINT/$INDEX/_settings"
      if [[ "$HTTP_CODE" != 200 ]]; then
        echo "!! $DEST exists but $INDEX is gone and not recorded as restored - check manually."
        FAILED=$INDEX; break
      fi
      echo "=== $INDEX (resuming: $DEST already exists)"
      if wait_until "reindex $INDEX -> $DEST" reindex_done && finish_extract; then
        COUNT=$((COUNT + 1)); (( COUNT >= MAX_BATCH )) && { echo "Reached max batch size of $MAX_BATCH. Stopping."; break; }
        continue
      fi
      FAILED=$INDEX; break
    fi
  fi

  echo "=== $INDEX"
  req "$RESTORE_OS_ENDPOINT/$INDEX/_settings"
  if [[ "$HTTP_CODE" == 404 ]]; then
    req -XPOST -H "Content-Type: application/json" "$RESTORE_OS_ENDPOINT/_snapshot/$SNAPSHOT_REPO/$INDEX/_restore" \
      -d "{\"indices\": \"$INDEX\", \"include_global_state\": false, \"partial\": false, \"include_aliases\": false, \"index_settings\": {\"index.number_of_replicas\": 0}}"
    [[ "$HTTP_CODE" == 200 ]] || { echo "  !! restore request failed: HTTP $HTTP_CODE $BODY"; FAILED=$INDEX; break; }
  else
    echo "  $INDEX already present on restore domain - resuming"
  fi
  wait_until "$INDEX green" is_green || { FAILED=$INDEX; break; }

  if [[ -n "$EXTRACT_NAMESPACE" ]]; then
    extract || { FAILED=$INDEX; break; }
  else
    req -XPOST "$RESTORE_OS_ENDPOINT/_ultrawarm/migration/$INDEX/_warm"
    [[ "$HTTP_CODE" == 200 ]] || { echo "  !! warm migration request failed: HTTP $HTTP_CODE $BODY"; FAILED=$INDEX; break; }
    echo "$INDEX" >>"$RESTORED_INDICES_FILE"
  fi

  COUNT=$((COUNT + 1))
  (( COUNT >= MAX_BATCH )) && { echo "Reached max batch size of $MAX_BATCH. Stopping."; break; }
done <"$TMP_FILE"

cat "$RESTORED_INDICES_FILE" >>"$EXISTING_RESTORED_FILE"
aws s3 cp "$EXISTING_RESTORED_FILE" "$S3_RESTORED_INDEX_FILE" || die "upload of $S3_RESTORED_INDEX_FILE failed"

echo "Batch complete. $COUNT indices restored."
echo "Total restored: $(grep -cv '^\s*$' "$EXISTING_RESTORED_FILE") / $TOTAL_INDICES_TO_RESTORE"
[[ -n "$FAILED" ]] && die "stopped at $FAILED - investigate before re-running"
exit 0
