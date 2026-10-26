#!/bin/bash
# Move existing COLD indices on the live app-logs domain onto the legal-hold-retain ISM policy
# (terraform/aws-accounts/cloud-platform-aws/account/app-opensearch-legal-hold.tf), deferring their deletion.
#
# Usage: ./legal-hold/change_policy_cold.sh <IS_PIPELINE> <apply|verify> [index-or-prefix*]
#   - With no 3rd arg, runs against every prefix in index_pattern_live_app_logs.
#   - Test on a single index first, e.g.  ./legal-hold/change_policy_cold.sh false apply manager_ipamd-2025.11.02
#
# AWS constraints for cold indices (?type=_cold): one index or pattern per call, wildcard only at the end.
# Only indices currently in the "cold" state are changed, so indices on other policies are untouched.

set -u

IS_PIPELINE=$1
MODE=$2
TARGET=${3:-}

ENDPOINT="https://app-logs.cloud-platform.service.justice.gov.uk"
POLICY_ID="legal-hold-retain"
PREFIXES=(
  "manager_eventrouter*"
  "live_kubernetes_cluster*"
  "live_kubernetes_ingress*"
  "live_eventrouter*"
  "manager_kubernetes_cluster-*"
  "manager_kubernetes_ingress-*"
  "manager_concourse-*"
  "live_ipamd-*"
  "manager_ipamd-*"
)

AUTH=(--user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" --aws-sigv4 "aws:amz:eu-west-2:es")
if [[ "$IS_PIPELINE" != true ]]; then
  AUTH+=(-H "x-amz-security-token: $AWS_SESSION_TOKEN")
fi

if [[ -n "$TARGET" ]]; then
  PREFIXES=("$TARGET")
fi

for p in "${PREFIXES[@]}"; do
  case "$MODE" in
    apply)
      echo "change_policy $p -> $POLICY_ID"
      curl -s -XPOST "${AUTH[@]}" -H "Content-Type: application/json" \
        "$ENDPOINT/_plugins/_ism/change_policy/$p?type=_cold" \
        -d "{\"policy_id\": \"$POLICY_ID\", \"state\": \"cold\", \"include\": [{\"state\": \"cold\"}]}"
      echo
      ;;
    verify)
      echo "explain $p (cold)"
      curl -s "${AUTH[@]}" "$ENDPOINT/_plugins/_ism/explain/$p?type=_cold" |
        jq -r 'to_entries[] | select(.value | type == "object") | .value.policy_id // "none"' | sort | uniq -c
      ;;
    *)
      echo "MODE must be apply or verify"
      exit 1
      ;;
  esac
done

exit 0
