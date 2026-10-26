#!/bin/bash
# Move existing COLD indices on the live app-logs domain onto the legal-hold-retain ISM policy
# (terraform/aws-accounts/cloud-platform-aws/account/app-opensearch-legal-hold.tf). See scripts/opensearch/README.md.
#
# Usage: ./legal-hold/change_policy_cold.sh <IS_PIPELINE> <mode> [arg]
#   plan     [index]  read-only: classify every cold index (or one index) and report what apply would do
#   apply    [index]  change_policy each eligible cold index, then poll until it is confirmed on the hold policy
#   verify   [index]  read-only: fail if any cold index is still eligible, at risk, or errored
#   preview-lift <N>  read-only: list held indices that would be DELETED if legal_hold_delete_transition were set to <N>d
#
# Calls are made per index: curl --aws-sigv4 does not sign wildcard paths correctly (403).
# Exit code is non-zero if anything needs attention. A per-index TSV report is written to $OUT_DIR (default .).

set -uo pipefail

IS_PIPELINE=${1:-}
MODE=${2:-}
ARG=${3:-}

ENDPOINT="https://app-logs.cloud-platform.service.justice.gov.uk"
HOLD_POLICY="legal-hold-retain"
SOURCE_POLICY="hot-warm-cold-delete"
PREFIXES=(manager_eventrouter live_kubernetes_cluster live_kubernetes_ingress live_eventrouter
  manager_kubernetes_cluster- manager_kubernetes_ingress- manager_concourse- live_ipamd- manager_ipamd-)
VERIFY_TIMEOUT_SECS=${VERIFY_TIMEOUT_SECS:-1800}
OUT_DIR=${OUT_DIR:-.}
REPORT="$OUT_DIR/legal-hold-${MODE}-$(date -u +%Y%m%dT%H%M%SZ).tsv"

die() { echo "FATAL: $*" >&2; exit 1; }
[[ "$IS_PIPELINE" == true || "$IS_PIPELINE" == false ]] || die "first arg must be true|false"
case "$MODE" in plan|apply|verify) ;; preview-lift) [[ "$ARG" =~ ^[0-9]+$ ]] || die "preview-lift needs a number of days" ;; *) die "mode must be plan|apply|verify|preview-lift" ;; esac

AUTH=(--user "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" --aws-sigv4 "aws:amz:eu-west-2:es")
[[ "$IS_PIPELINE" != true ]] && AUTH+=(-H "x-amz-security-token: $AWS_SESSION_TOKEN")

# req <curl args...> -> sets HTTP_CODE and BODY; aborts the whole run on auth failure
req() {
  local out
  out=$(curl -s -w $'\n%{http_code}' "${AUTH[@]}" "$@") || out=$'\n000'
  HTTP_CODE=${out##*$'\n'}
  BODY=${out%$'\n'*}
  [[ "$HTTP_CODE" == 401 || "$HTTP_CODE" == 403 ]] && die "HTTP $HTTP_CODE on $* – credentials expired or not permitted"
  return 0
}

# --- preflight ---------------------------------------------------------------------------------
req "$ENDPOINT/_cluster/health"
[[ "$HTTP_CODE" == 200 ]] || die "cannot reach $ENDPOINT (HTTP $HTTP_CODE)"
HOLD_SEQ=""
req "$ENDPOINT/_plugins/_ism/policies/$HOLD_POLICY"
if [[ "$HTTP_CODE" != 200 ]]; then
  [[ "$MODE" == apply ]] && die "policy $HOLD_POLICY not found – apply the terraform first"
  echo "WARNING: policy $HOLD_POLICY not found on the domain"
else
  cold_actions=$(jq '[.policy.states[] | select(.name == "cold") | .actions | length] | first // -1' <<<"$BODY")
  hold_age=$(jq -r '[.policy.states[] | select(.name == "cold") | .transitions[]?.conditions.min_index_age] | first // "none"' <<<"$BODY")
  HOLD_SEQ=$(jq -r '._seq_no' <<<"$BODY")
  [[ "$cold_actions" == 0 ]] || die "$HOLD_POLICY 'cold' state must have no actions (found $cold_actions)"
  echo "Hold policy $HOLD_POLICY: cold state has no actions, deletes at min_index_age=$hold_age"
fi

# --- list cold indices (index, creation_date, size) via the paginated cold API --------------------
COLD=$(mktemp); trap 'rm -f "$COLD"' EXIT
req "$ENDPOINT/_cold/indices/_search"
[[ "$HTTP_CODE" == 200 ]] || die "cold index listing failed (HTTP $HTTP_CODE)"
total=$(jq -r '.total_results' <<<"$BODY")
while :; do
  n=$(jq '.indices | length' <<<"$BODY")
  [[ "$n" -eq 0 ]] && break
  jq -r '.indices[] | [.index, .creation_date, .size] | @tsv' <<<"$BODY" >>"$COLD"
  page=$(jq -r '.pagination_id // empty' <<<"$BODY")
  [[ -z "$page" ]] && break
  req -XPOST -H "Content-Type: application/json" "$ENDPOINT/_cold/indices/_search" -d "{\"pagination_id\": \"$page\"}"
  [[ "$HTTP_CODE" == 200 ]] || die "cold index listing failed mid-pagination (HTTP $HTTP_CODE)"
done
listed=$(wc -l <"$COLD" | tr -d ' ')
[[ "$listed" -eq "$total" ]] || die "cold listing incomplete: got $listed of $total"

TARGETS=()
while IFS=$'\t' read -r idx _ _; do
  if [[ "$MODE" != preview-lift && -n "$ARG" ]]; then [[ "$idx" == "$ARG" ]] && TARGETS+=("$idx"); continue; fi
  for p in "${PREFIXES[@]}"; do [[ "$idx" == "$p"* ]] && { TARGETS+=("$idx"); break; }; done
done <"$COLD"
[[ -n "$ARG" && "$MODE" != preview-lift && ${#TARGETS[@]} -eq 0 ]] && die "$ARG is not a cold index"
echo "Cold indices on domain: $total; in scope: ${#TARGETS[@]}"

# --- classify ------------------------------------------------------------------------------------
# classes: HELD HELD_STALE CANDIDATE STALLED STALLED_DELETE UNMANAGED OTHER AT_RISK_DELETE ERROR
# HELD_STALE = on the hold policy but an older version (e.g. after legal_hold_delete_transition changed)
classify() {
  req "$ENDPOINT/_plugins/_ism/explain/$1?type=_cold"
  [[ "$HTTP_CODE" == 200 ]] || { echo -e "ERROR\t-\t-\t-\t-\texplain HTTP $HTTP_CODE"; return; }
  jq -r --arg i "$1" --arg hold "$HOLD_POLICY" --arg src "$SOURCE_POLICY" --arg hseq "$HOLD_SEQ" '
    .[$i] as $m
    | ($m.policy_id // $m["index.plugins.index_state_management.policy_id"] // "none") as $p
    | ($m.state.name // "-") as $s
    | ($m.action.name // "-") as $a
    | (if $p == $hold then (if $hseq == "" or (($m.policy_seq_no | tostring) == $hseq) then "HELD" else "HELD_STALE" end)
       elif ($s == "delete" or $a == "cold_delete") then (if $m.enabled == false then "STALLED_DELETE" else "AT_RISK_DELETE" end)
       elif $p == "none" then "UNMANAGED"
       elif $m.enabled == false or $m.action.failed == true then "STALLED"
       elif $p == $src and $s == "cold" then "CANDIDATE"
       else "OTHER" end) as $c
    | [$c, $p, $s, $a, ($m.enabled | tostring), ($m.info.message // "" | gsub("[\t\n]"; " "))] | @tsv' <<<"$BODY"
}

echo -e "index\tclass\tpolicy\tstate\taction\tenabled\tage_days\tsize_bytes\tdetail" >"$REPORT"
now=$(date -u +%s)
i=0
for idx in "${TARGETS[@]}"; do
  i=$((i + 1)); (( i % 200 == 0 )) && echo "  classified $i/${#TARGETS[@]}"
  IFS=$'\t' read -r c p s a e d < <(classify "$idx")
  created=$(awk -F'\t' -v x="$idx" '$1 == x {print $2}' "$COLD")
  size=$(awk -F'\t' -v x="$idx" '$1 == x {print $3}' "$COLD")
  age=$(( (now - $(date -u -j -f "%Y-%m-%dT%H:%M:%S" "${created%%.*}" +%s 2>/dev/null || date -u -d "$created" +%s)) / 86400 ))
  echo -e "$idx\t$c\t$p\t$s\t$a\t$e\t$age\t$size\t$d" >>"$REPORT"
done

has_class() { awk -F'\t' -v re="^($1)$" 'NR > 1 && $2 ~ re {f = 1} END {exit !f}' "$REPORT"; }
set_class() { awk -F'\t' -v OFS='\t' -v i="$1" -v c="$2" '$1 == i {$2 = c} {print}' "$REPORT" >"$REPORT.tmp" && mv "$REPORT.tmp" "$REPORT"; }
class_of() { awk -F'\t' -v i="$1" '$1 == i {print $2}' "$REPORT"; }

summary() {
  echo; echo "Summary ($MODE):"
  cut -f2 "$REPORT" | tail -n +2 | sort | uniq -c
  has_class STALLED_DELETE && { echo "  WARNING STALLED_DELETE (delete failed, policy disabled – an ISM retry on these would delete them):"; awk -F'\t' '$2 == "STALLED_DELETE" {print "     " $1 "  " $9}' "$REPORT"; }
  for bad in AT_RISK_DELETE ERROR HELD_STALE FAIL_CHANGE FAIL_NOT_APPLIED; do
    has_class "$bad" && { echo "  !! $bad:"; awk -F'\t' -v b="$bad" '$2 == b {print "     " $1 "  " $9}' "$REPORT"; }
  done
  echo "Report: $REPORT"
}

reminder() {
  cat <<'EOF'

==================================================================================================
 REMINDER – legal hold is an ongoing obligation, not a one-off change:
  * Indices that move to cold AFTER this run are still on hot-warm-cold-delete and will be deleted
    at 366 days. Re-run "apply" (then "verify") at least weekly for as long as the hold is needed.
  * Held indices are kept until the hold is lifted and keep accruing cold-storage cost.
  * Record both of the above as explicit TODOs in your ticket, with a review/end date.
  * Lifting: NEVER just set legal_hold_delete_transition back to 366d – every held index older than
    that is deleted on the next ISM run. Use "preview-lift <days>" and step down in batches.
==================================================================================================
EOF
}

case "$MODE" in
  plan)
    summary
    awk -F'\t' '$2 == "CANDIDATE" || $2 == "HELD_STALE"' "$REPORT" | wc -l | xargs echo "apply would change:"
    has_class "AT_RISK_DELETE|ERROR" && exit 2
    exit 0
    ;;

  preview-lift)
    echo; echo "Held indices that would be DELETED on the next ISM run if legal_hold_delete_transition=${ARG}d:"
    awk -F'\t' -v n="$ARG" 'NR > 1 && ($2 == "HELD" || $2 == "HELD_STALE") && $7 >= n {c++; s += $8; print "  " $1 "  age=" $7 "d"} END {printf "TOTAL: %d indices, %.1f TB\n", c, s / 1e12}' "$REPORT"
    echo "Report: $REPORT"
    exit 0
    ;;

  verify)
    summary
    reminder
    has_class "CANDIDATE|HELD_STALE|AT_RISK_DELETE|ERROR" && { echo "VERIFY FAILED: indices above are not held"; exit 1; }
    echo "VERIFY OK"
    exit 0
    ;;

  apply)
    has_class "AT_RISK_DELETE|ERROR" && { summary; die "resolve AT_RISK_DELETE / ERROR indices before applying"; }
    QUEUED=()
    for idx in "${TARGETS[@]}"; do
      case "$(class_of "$idx")" in CANDIDATE|HELD_STALE) ;; *) continue ;; esac
      req -XPOST -H "Content-Type: application/json" "$ENDPOINT/_plugins/_ism/change_policy/$idx?type=_cold" \
        -d "{\"policy_id\": \"$HOLD_POLICY\", \"state\": \"cold\", \"include\": [{\"state\": \"cold\"}]}"
      if [[ "$HTTP_CODE" == 200 && $(jq -r '.updated_indices' <<<"$BODY") == 1 && $(jq -r '.failures' <<<"$BODY") == false ]]; then
        QUEUED+=("$idx")
      else
        set_class "$idx" FAIL_CHANGE
        echo "  !! change_policy failed for $idx: HTTP $HTTP_CODE $(jq -c '.failed_indices // .error // .' <<<"$BODY" | cut -c1-200)"
      fi
    done
    echo "change_policy queued for ${#QUEUED[@]} indices; waiting for ISM to apply (async, up to ${VERIFY_TIMEOUT_SECS}s)"

    deadline=$(( $(date +%s) + VERIFY_TIMEOUT_SECS ))
    PENDING=("${QUEUED[@]+"${QUEUED[@]}"}")
    while [[ ${#PENDING[@]} -gt 0 && $(date +%s) -lt $deadline ]]; do
      sleep 60
      STILL=()
      for idx in "${PENDING[@]}"; do
        IFS=$'\t' read -r c _ _ _ _ _ < <(classify "$idx")
        case "$c" in
          HELD) set_class "$idx" HELD ;;
          AT_RISK_DELETE|ERROR) set_class "$idx" "$c"; echo "  !! $idx became $c" ;;
          *) STILL+=("$idx") ;;
        esac
      done
      PENDING=("${STILL[@]+"${STILL[@]}"}")
      echo "  $(date -u +%T) still pending: ${#PENDING[@]}"
    done
    for idx in "${PENDING[@]+"${PENDING[@]}"}"; do
      set_class "$idx" FAIL_NOT_APPLIED
    done

    summary
    reminder
    has_class "FAIL_CHANGE|FAIL_NOT_APPLIED|AT_RISK_DELETE|ERROR" && { echo "APPLY FAILED: see indices above"; exit 1; }
    echo "APPLY OK"
    exit 0
    ;;
esac
