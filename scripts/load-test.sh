#!/usr/bin/env bash
set -euo pipefail

# Start in one terminal:
# kubectl port-forward -n devops svc/employee-api-service 8081:80
# Install hey before running: https://github.com/rakyll/hey
TARGET_URL="${1:-http://127.0.0.1:8081/api/employees}"
DURATION="${DURATION:-180s}"
CONCURRENCY="${CONCURRENCY:-30}"

if ! command -v hey >/dev/null 2>&1; then
  echo "The 'hey' load-test tool is required. Install it, then rerun this script." >&2
  exit 1
fi

echo "Target: $TARGET_URL"
echo "Duration: $DURATION; concurrency: $CONCURRENCY"
echo "Watch HPA in another terminal: kubectl get hpa employee-api-hpa -n devops -w"
hey -z "$DURATION" -c "$CONCURRENCY" "$TARGET_URL"
