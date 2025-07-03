#!/bin/bash

set -u

TODAY=$(date +%Y.%m.%d)
USE_SESSION_TOKEN=$1
PAGE_ID=0
INDEX_LENGTH=99
COUNTER=0
COLD_INDICES_THRESHOLD=2755 # update later

touch cold_indices_json/random.json
rm cold_indices_json/*json

if [ $PAGE_ID -eq 0 ]; then
    RESP=$(curl -sL --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY  ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_cold/indices/_search | jq '.')
    PAGE_ID=$(echo "$RESP" | jq -r '. | .pagination_id')
    echo "$RESP" > "cold_indices_json/$COUNTER.json"
    COUNTER=$((COUNTER+1))
fi

while [ -n "$PAGE_ID" ] || [ $PAGE_ID != null ] && [ $INDEX_LENGTH -ne 0 ];
do
    RESP=$(curl -sL -H "Content-Type: application/json" --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY ${USE_SESSION_TOKEN:+ -H "x-amz-security-token: $AWS_SESSION_TOKEN"} --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_cold/indices/_search -d '{ "pagination_id": "'$PAGE_ID'" }' | jq '.')
    PAGE_ID=$(echo "$RESP" | jq -r '. | .pagination_id')
    echo "$RESP" > "cold_indices_json/$COUNTER.json"
    INDEX_LENGTH=$(echo $RESP | jq '. | .indices | length')

    sleep 0.3
    COUNTER=$((COUNTER+1))
done

jq -s '.[0].indices=([.[].indices] | flatten) | .[0]' cold_indices_json/*json > collated_cold_indices

COLD_INDEXES=$(jq -r '.indices[].index' collated_cold_indices)

send_slack_alert() {
  local message="$1"
  curl -s -X POST -H 'Content-type: application/json' \
    --data "{\"channel\": \"#lower-priority-alarms\", \"text\": \"$message\"}" \
    "$SLACK_WEBHOOK_URL"
}

FUTURE_INDICES_LIST=""
for index in $COLD_INDEXES; do
  date_part=$(echo "$index" | grep -oE '[0-9]{4}\.[0-9]{2}\.[0-9]{2}')
  if [[ -n "$date_part" && "$date_part" > "$TODAY" ]]; then
    echo "Future cold index found: $index"
    FUTURE_INDICES_LIST+="$index\n"
  fi
done

# uncomment below when the indices are stable or else the alert will keep coming
# if [[ -n "$FUTURE_INDICES_LIST" ]]; then
#   send_slack_alert "⚠️ *OpenSearch \`Cold\` indices contain future-dated index names.* Please investigate.\n\`\`\`\n$FUTURE_INDICES_LIST\`\`\`\n"
# fi

COLD_COUNT=$(echo "$COLD_INDEXES" | wc -w | awk '{print $1}')
echo "$COLD_COUNT"

if [[ "$COLD_COUNT" -gt "$COLD_INDICES_THRESHOLD" ]]; then
  send_slack_alert "⚠️ *OpenSearch \`Cold\` index count above expected*: found \`$COLD_COUNT\`, expected \`$COLD_INDICES_THRESHOLD\`.\nThis may indicate some cold indices failed to delete. Please investigate."
# uncomment below when the indices are stable
# elif [[ "$COLD_COUNT" -lt "$COLD_INDICES_THRESHOLD" ]]; then
#   send_slack_alert "⚠️ *OpenSearch \`Cold\` index count below expected*: found \`$COLD_COUNT\`, expected \`$COLD_INDICES_THRESHOLD\`.\nThis may suggest missing indices. Please investigate."
else
  echo "Cold index count matches expected value."
fi
