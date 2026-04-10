#!/bin/bash
# Test Discipline: Skipped Test Detection
# Max 5% of tests can be @Disabled. Beyond that, delete or fix them.

set -uo pipefail

TEST_DIR="src/test/java"
MAX_SKIP_PERCENT=5

if [ ! -d "$TEST_DIR" ]; then
  echo "No test directory — skipping"
  exit 0
fi

TOTAL_TESTS=0
DISABLED_TESTS=0

# Count files containing @Test
while IFS= read -r line; do
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
done < <(grep -rl "@Test" "$TEST_DIR" --include="*.java" 2>/dev/null || true)

# Count files containing @Disabled
while IFS= read -r line; do
  if [ -n "$line" ]; then
    DISABLED_TESTS=$((DISABLED_TESTS + 1))
  fi
done < <(grep -rl "@Disabled" "$TEST_DIR" --include="*.java" 2>/dev/null || true)

if [ "$TOTAL_TESTS" -eq 0 ]; then
  echo "No tests found — skipping"
  exit 0
fi

SKIP_PERCENT=$((DISABLED_TESTS * 100 / TOTAL_TESTS))

if [ "$SKIP_PERCENT" -gt "$MAX_SKIP_PERCENT" ]; then
  echo "BLOCKED: ${SKIP_PERCENT}% tests disabled (${DISABLED_TESTS}/${TOTAL_TESTS}). Max: ${MAX_SKIP_PERCENT}%"
  echo "Fix: Delete stale @Disabled tests or fix the underlying issue"
  exit 1
fi

echo "Skipped tests: ${DISABLED_TESTS}/${TOTAL_TESTS} (${SKIP_PERCENT}%) — OK (max ${MAX_SKIP_PERCENT}%)"
exit 0
