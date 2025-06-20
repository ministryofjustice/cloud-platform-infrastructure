#!/bin/bash

set -eu

if [[ "$IS_PIPELINE" = true ]]; then
    PIPELINE_AWS_SESSION_TOKEN=-""
else
    PIPELINE_AWS_SESSION_TOKEN="-H \"x-amz-security-token: $AWS_SESSION_TOKEN\""
fi

./get_all_cold_and_warm_indices.sh "$PIPELINE_AWS_SESSION_TOKEN"
./get_failed_cold.sh "$PIPELINE_AWS_SESSION_TOKEN"
./retrigger_stuck_warm.sh "$PIPELINE_AWS_SESSION_TOKEN"
