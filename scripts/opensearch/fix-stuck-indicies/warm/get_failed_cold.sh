#!/bin/bash

set -eu

TODAY=$(date +"%Y%m%d")

if [[ "$IS_PIPELINE" = true ]]; then
    PIPELINE_AWS_SESSION_TOKEN=-""
else
    PIPELINE_AWS_SESSION_TOKEN="-H \"x-amz-security-token: $AWS_SESSION_TOKEN\""
fi

ISM_POLICY_STATE_JSON=$(curl -L --user $AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY "${PIPELINE_AWS_SESSION_TOKEN}" --aws-sigv4 "aws:amz:eu-west-2:es" https://app-logs.cloud-platform.service.justice.gov.uk/_plugins/_ism/explain/_all)

RESTRUCTURED_JSON=$(echo $ISM_POLICY_STATE_JSON | jq '[.[] | {index: .index?, state: .action?.failed?, cause: .info?.cause?, message: .info?.message?}]')

COLD_INDEXES=$(echo $RESTRUCTURED_JSON | jq '[.[] | select(.message != null) | select(.message? | contains("Failed to start cold migration")) | select(.index)]')

echo $COLD_INDEXES | jq '.' > failed_cold_indices_$TODAY

jq -rc '.[]' failed_cold_indices_$TODAY > compacted_failed_cold

exit 0

