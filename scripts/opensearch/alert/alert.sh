#!/bin/bash

set -eu

IS_PIPELINE=$1

if [[ "$IS_PIPELINE" = true ]]; then
    USE_SESSION_TOKEN=false
else
    USE_SESSION_TOKEN=true
fi

./hot_and_warm_indices_alert.sh "$USE_SESSION_TOKEN"
./cold_indices_alert.sh "$USE_SESSION_TOKEN"