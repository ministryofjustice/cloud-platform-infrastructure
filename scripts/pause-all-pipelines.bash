#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [pause|unpause] [target]"
  exit 1
}

ACTION="${1:-pause}"
TARGET="${2:-manager}"

case "$ACTION" in
  pause|unpause) ;;
  *) usage ;;
esac

PIPELINES=$(fly -t "$TARGET" pipelines | awk 'NR>1 {print $2}')

echo "The following pipelines on target '$TARGET' will be ${ACTION}d:"
echo "$PIPELINES"
echo

read -r -p "Proceed with ${ACTION}ing all pipelines on target '$TARGET'? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

echo "$PIPELINES" | while read -r pipeline; do
  echo "${ACTION}ing $pipeline"
  fly -t "$TARGET" "$ACTION"-pipeline -p "$pipeline"
done
