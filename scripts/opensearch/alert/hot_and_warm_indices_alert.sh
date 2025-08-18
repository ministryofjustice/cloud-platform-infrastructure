#!/bin/bash

set -eu

USE_SESSION_TOKEN=$1
# we have 9 indices
# hot = 9 * 1 = 9
# warm = 9 * 30 = 270
# update the threshold when the indices are stable
HOT_INDICES_THRESHOLD=18 # some buffer for reindex

WARM_INDICES_THRESHOLD=280 # some buffer for warm migration

HOT_COUNT=$(curl -sL \
  --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
  ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
  --aws-sigv4 "aws:amz:eu-west-2:es" \
  "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_hot" \
  | awk '{ print $3 }' \
  | grep -v '^\.' \
  | grep -v 'reindex' \
  | wc -l \
  | awk '{print $1}')

WARM_COUNT=$(curl -sL \
  --user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
  ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} \
  --aws-sigv4 "aws:amz:eu-west-2:es" \
  "https://app-logs.cloud-platform.service.justice.gov.uk/_cat/indices/_warm" \
  | awk '{ print $3 }' \
  | grep -v '^\.' \
  | grep -v 'reindex' \
  | wc -l \
  | awk '{print $1}')

echo "Hot indices count: $HOT_COUNT"

echo "Warm indices count: $WARM_COUNT"

send_slack_alert() {
  local message="$1"
  curl -s -X POST -H 'Content-type: application/json' \
    --data "{\"channel\": \"#lower-priority-alarms\", \"text\": \"$message\"}" \
    "$SLACK_WEBHOOK_URL"
}

if [[ "$HOT_COUNT" -gt "$HOT_INDICES_THRESHOLD" ]]; then
  send_slack_alert "⚠️ *OpenSearch \`Hot\` index count above expected*: found \`$HOT_COUNT\`, expected \`$HOT_INDICES_THRESHOLD\`.\nThis may indicate indices have not transitioned to warm as expected — some indices may have oversized shards. Please investigate."
# uncomment below when the indices are stable
# elif [[ "$HOT_COUNT" -lt "$HOT_INDICES_THRESHOLD" ]]; then
#   send_slack_alert "⚠️ *OpenSearch \`Hot\` index count below expected*: found \`$HOT_COUNT\`, expected \`$HOT_INDICES_THRESHOLD\`.\nThis may indicate missing indices. Please investigate."
else
  echo "Hot index count matches expected value."
fi

if [[ "$WARM_COUNT" -gt "$WARM_INDICES_THRESHOLD" ]]; then
  send_slack_alert "⚠️ *OpenSearch \`Warm\` index count above expected*: found \`$WARM_COUNT\`, expected \`$WARM_INDICES_THRESHOLD\`.\nThis may indicate indices have not transitioned to cold as expected — some indices may exist in both warm and cold. Please investigate."
# uncomment below when the indices are stable
# elif [[ "$WARM_COUNT" -lt "$WARM_INDICES_THRESHOLD" ]]; then
#   send_slack_alert "⚠️ *OpenSearch \`Warm\` index count below expected*: found \`$WARM_COUNT\`, expected \`$WARM_INDICES_THRESHOLD\`.\nThis may indicate missing indices. Please investigate."
else
  echo "Warm index count matches expected value."
fi
