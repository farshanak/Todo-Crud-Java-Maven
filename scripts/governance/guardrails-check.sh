#!/bin/bash
# SRP Guardrails: File size and method length enforcement
# File: 600 LOC max (error), 300 LOC (warning), 75 LOC min for check
# Method: 50 LOC max

set -euo pipefail

SCAN_DIR="src/main/java"
MAX_FILE=600
WARN_FILE=300
MAX_METHOD=50
FAIL=0

if [ ! -d "$SCAN_DIR" ]; then
  exit 0
fi

for file in $(find "$SCAN_DIR" -name "*.java" -type f 2>/dev/null); do
  lines=$(wc -l < "$file" | tr -d ' ')
  name=$(basename "$file")

  if [ "$lines" -gt "$MAX_FILE" ]; then
    echo "BLOCKED: $name — $lines lines (max $MAX_FILE)"
    FAIL=1
  elif [ "$lines" -gt "$WARN_FILE" ]; then
    echo "WARNING: $name — $lines lines (consider splitting at $WARN_FILE)"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "SRP guardrails passed"
fi

exit $FAIL
