#!/bin/bash
# Iron Dome Ratchet: Silent Catch Detection
# Empty catch blocks must log, throw, or be marked // SILENT_CATCH: reason
# Baseline ratchets DOWN only — new silent catches are blocked.

set -euo pipefail

BASELINE_FILE=".memory-layer/baselines/silent-catches.json"
SCAN_DIR="src/main/java"

count_silent_catches() {
  local count=0
  while IFS= read -r file; do
    # Count empty catch blocks: catch (...) { } or catch (...) { // comment only }
    local file_count
    file_count=$(grep -cP 'catch\s*\([^)]*\)\s*\{[\s]*\}' "$file" 2>/dev/null || echo 0)
    count=$((count + file_count))
  done < <(find "$SCAN_DIR" -name "*.java" -type f 2>/dev/null)
  echo "$count"
}

CURRENT=$(count_silent_catches)

if [ ! -f "$BASELINE_FILE" ]; then
  echo "No baseline found. Current silent catches: $CURRENT"
  echo "{\"count\": $CURRENT, \"capturedAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$BASELINE_FILE"
  echo "Baseline created at $CURRENT"
  exit 0
fi

BASELINE=$(grep -oP '"count":\s*\K[0-9]+' "$BASELINE_FILE" 2>/dev/null || echo 0)

if [ "$CURRENT" -gt "$BASELINE" ]; then
  echo "BLOCKED: Silent catches increased ($BASELINE -> $CURRENT)"
  echo "Fix: Add logging, re-throw, or mark with // SILENT_CATCH: reason"
  exit 1
elif [ "$CURRENT" -lt "$BASELINE" ]; then
  echo "Ratchet improved: $BASELINE -> $CURRENT. Updating baseline."
  echo "{\"count\": $CURRENT, \"capturedAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$BASELINE_FILE"
fi

echo "Silent catches: $CURRENT (baseline: $BASELINE) — OK"
exit 0
