#!/bin/bash
# Snapshot cold app-logs indices listed in S3, one at a time. Stops on the first failure.
# Usage: ./take_snapshot_cold_indices.sh <true|false>  Env: MAX_BATCH, STEP_TIMEOUT_SECS, EXPECTED_COLD_POLICY

set -uo pipefail

IS_PIPELINE=${1:-}
[[ "$IS_PIPELINE" == true || "$IS_PIPELINE" == false ]] || { echo "usage: $0 <true|false>"; exit 1; }

LIVE_OS_ENDPOINT="https://app-logs.cloud-platform.service.justice.gov.uk"
SNAPSHOT_REPO="cp-live-app-logs-snapshot-s3-repository"
S3_SOURCE_INDEX_FILE="s3://cloud-platform-concourse-environments-live-reports/opensearch-snapshots/source-index-list.txt"
MAX_BATCH=${MAX_BATCH:-10}
STEP_TIMEOUT_SECS=${STEP_TIMEOUT_SECS:-3600}
EXPECTED_COLD_POLICY=${EXPECTED_COLD_POLICY-legal-hold-retain}

LOCAL_INDEX_FILE="index_list.txt"
TMP_FILE="$(mktemp)"
COUNT=0

AUTH=(--user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" --aws-sigv4 "aws:amz:eu-west-2:es")
[[ "$IS_PIPELINE" != true ]] && AUTH+=(-H "x-amz-security-token: $AWS_SESSION_TOKEN")

die() { echo "FATAL: $*" >&2; exit 1; }

# Sets HTTP_CODE and BODY. Aborts on 401/403.
req() {
  local out
  out=$(curl -s -w $'\n%{http_code}' "${AUTH[@]}" "$@") || out=$'\n000'
  HTTP_CODE=${out##*$'\n'}
  BODY=${out%$'\n'*}
  [[ "$HTTP_CODE" == 401 || "$HTTP_CODE" == 403 ]] && die "HTTP $HTTP_CODE on $* - credentials expired or not permitted"
  return 0
}

# Polls a function every 30s until it succeeds or STEP_TIMEOUT_SECS passes.
wait_until() {
  local what=$1 fn=$2 deadline=$(( $(date +%s) + STEP_TIMEOUT_SECS ))
  until "$fn"; do
    [[ $(date +%s) -ge $deadline ]] && { echo "  timed out waiting for: $what"; return 1; }
    sleep 30
  done
}

is_warm_green() {
  req "$LIVE_OS_ENDPOINT/$INDEX/_settings?filter_path=*.settings.index.routing.allocation.require._box_type,*.settings.index.routing.allocation.require.box_type"
  [[ "$HTTP_CODE" == 200 && "$BODY" == *warm* ]] || return 1
  req "$LIVE_OS_ENDPOINT/_cluster/health/$INDEX"
  [[ "$HTTP_CODE" == 200 && $(jq -r '.status' <<<"$BODY") == green ]]
}

is_cold() {
  req "$LIVE_OS_ENDPOINT/$INDEX/_settings"
  [[ "$HTTP_CODE" == 404 ]] || return 1 # no longer hot/warm
  req "$LIVE_OS_ENDPOINT/_plugins/_ism/explain/$INDEX?type=_cold"
  [[ "$HTTP_CODE" == 200 && $(jq -r --arg i "$INDEX" '.[$i] != null' <<<"$BODY") == true ]]
}

snapshot_done() {
  req "$LIVE_OS_ENDPOINT/_snapshot/$SNAPSHOT_REPO/$INDEX"
  SNAP_STATE=$(jq -r '.snapshots[0].state // "UNKNOWN"' <<<"$BODY")
  [[ "$SNAP_STATE" == SUCCESS || "$SNAP_STATE" == FAILED || "$SNAP_STATE" == PARTIAL ]]
}

back_to_cold() {
  echo "  migrating $INDEX back to cold..."
  req -XPOST -H "Content-Type: application/json" "$LIVE_OS_ENDPOINT/_ultrawarm/migration/$INDEX/_cold" -d '{"timestamp_field": "@timestamp"}'
  [[ "$HTTP_CODE" == 200 ]] || { echo "  !! cold migration request failed: HTTP $HTTP_CODE $BODY"; return 1; }
  wait_until "$INDEX back in cold" is_cold || return 1
  if [[ -n "$EXPECTED_COLD_POLICY" ]]; then
    req "$LIVE_OS_ENDPOINT/_plugins/_ism/explain/$INDEX?type=_cold"
    local p
    p=$(jq -r --arg i "$INDEX" '.[$i].policy_id // "none"' <<<"$BODY")
    [[ "$p" == "$EXPECTED_COLD_POLICY" ]] || { echo "  !! $INDEX is cold but on policy '$p', expected '$EXPECTED_COLD_POLICY'"; return 1; }
  fi
  echo "  $INDEX is cold${EXPECTED_COLD_POLICY:+ and on $EXPECTED_COLD_POLICY}"
}

echo "Downloading index list from $S3_SOURCE_INDEX_FILE"
aws s3 cp "$S3_SOURCE_INDEX_FILE" "$LOCAL_INDEX_FILE" || die "cannot download $S3_SOURCE_INDEX_FILE"
req "$LIVE_OS_ENDPOINT/_cluster/health"
[[ "$HTTP_CODE" == 200 ]] || die "cannot reach $LIVE_OS_ENDPOINT (HTTP $HTTP_CODE)"

FAILED=""
while IFS= read -r INDEX || [[ -n "$INDEX" ]]; do
  INDEX="${INDEX//$'\r'/}"

  if [[ -n "$FAILED" || -z "$INDEX" || "$INDEX" =~ ^# || "$INDEX" =~ ^snapshot-taken- ]] || (( COUNT >= MAX_BATCH )); then
    echo "$INDEX" >>"$TMP_FILE"
    continue
  fi

  echo "=== $INDEX"
  req -XPOST -H "Content-Type: application/json" "$LIVE_OS_ENDPOINT/_cold/migration/_warm" -d "{\"indices\": \"$INDEX\"}"
  if [[ "$HTTP_CODE" != 200 || $(jq -r '.failed_indices | length' <<<"$BODY") != 0 ]]; then
    echo "  !! cold->warm request failed: HTTP $HTTP_CODE $BODY"; FAILED=$INDEX; echo "$INDEX" >>"$TMP_FILE"; continue
  fi
  if ! wait_until "$INDEX green in warm" is_warm_green; then
    FAILED=$INDEX; echo "$INDEX" >>"$TMP_FILE"; continue
  fi

  echo "  taking snapshot $INDEX..."
  req -XPUT -H "Content-Type: application/json" "$LIVE_OS_ENDPOINT/_snapshot/$SNAPSHOT_REPO/$INDEX" \
    -d "{\"indices\": \"$INDEX\", \"include_global_state\": false, \"partial\": false}"
  SNAP_OK=false
  if [[ "$HTTP_CODE" == 200 ]]; then
    # The snapshot must contain only this index
    req "$LIVE_OS_ENDPOINT/_snapshot/$SNAPSHOT_REPO/$INDEX"
    if [[ $(jq -c '.snapshots[0].indices' <<<"$BODY") != "[\"$INDEX\"]" ]]; then
      echo "  !! snapshot contents unexpected: $(jq -c '.snapshots[0].indices | length' <<<"$BODY") indices - deleting it"
      req -XDELETE "$LIVE_OS_ENDPOINT/_snapshot/$SNAPSHOT_REPO/$INDEX"
    elif wait_until "snapshot $INDEX" snapshot_done && [[ "$SNAP_STATE" == SUCCESS ]]; then
      SNAP_OK=true
    else
      echo "  !! snapshot $INDEX ended as ${SNAP_STATE:-unknown}"
    fi
  else
    echo "  !! snapshot request failed: HTTP $HTTP_CODE $BODY"
  fi

  if back_to_cold && [[ "$SNAP_OK" == true ]]; then
    echo "snapshot-taken-$INDEX" >>"$TMP_FILE"
    COUNT=$((COUNT + 1))
  else
    FAILED=$INDEX
    echo "$INDEX" >>"$TMP_FILE"
  fi
done <"$LOCAL_INDEX_FILE"

echo "Uploading updated index list to $S3_SOURCE_INDEX_FILE"
mv "$TMP_FILE" "$LOCAL_INDEX_FILE"
aws s3 cp "$LOCAL_INDEX_FILE" "$S3_SOURCE_INDEX_FILE" || die "upload of $S3_SOURCE_INDEX_FILE failed"

echo "Batch complete. $COUNT index snapshots taken."
echo "Snapshot progress: $(grep -c '^snapshot-taken-' "$LOCAL_INDEX_FILE") / $(grep -cv '^\s*$' "$LOCAL_INDEX_FILE") indices completed."
[[ -n "$FAILED" ]] && die "stopped at $FAILED - check it is back in cold and on the expected policy before re-running"
exit 0
