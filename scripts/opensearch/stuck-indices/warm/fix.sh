#!/bin/bash

set -eu

IS_PIPELINE=$1

if [[ "$IS_PIPELINE" = true ]]; then
    USE_SESSION_TOKEN=false
else
    USE_SESSION_TOKEN=true
fi

./warm/get_all_cold_and_warm_indices.sh "$USE_SESSION_TOKEN"
./warm/get_failed_cold.sh "$USE_SESSION_TOKEN"
./warm/retrigger_stuck_warm.sh "$USE_SESSION_TOKEN"
