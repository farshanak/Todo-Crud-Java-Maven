#!/bin/bash
# Rising Tide: Mock Tax Enforcement (2x Rule)
# If a test file is >2x larger than its source, reject it.
# Solution: Delete bloated unit test, write integration test instead.

set -euo pipefail

MAX_RATIO=2.0
MIN_SOURCE_LINES=15
FAIL=0

SRC_DIR="src/main/java/com/example/todo"
TEST_DIR="src/test/java/com/example/todo/unit"

if [ ! -d "$TEST_DIR" ]; then
  echo "No unit test directory found — skipping mock tax check"
  exit 0
fi

for test_file in $(find "$TEST_DIR" -name "*Test.java" -type f 2>/dev/null); do
  # Map test file to source file
  test_name=$(basename "$test_file" | sed 's/Test\.java/.java/')
  src_file=$(find "$SRC_DIR" -name "$test_name" -not -path "*/test/*" -type f 2>/dev/null | head -1)

  if [ -z "$src_file" ]; then
    continue
  fi

  test_lines=$(wc -l < "$test_file" | tr -d ' ')
  src_lines=$(wc -l < "$src_file" | tr -d ' ')

  if [ "$src_lines" -lt "$MIN_SOURCE_LINES" ]; then
    continue
  fi

  # Check if test has mocking (Mockito imports)
  if ! grep -q "mock\|Mock\|when\|verify" "$test_file" 2>/dev/null; then
    continue
  fi

  ratio=$(echo "scale=1; $test_lines / $src_lines" | bc 2>/dev/null || echo "0")
  exceeds=$(echo "$ratio > $MAX_RATIO" | bc 2>/dev/null || echo "0")

  if [ "$exceeds" -eq 1 ]; then
    echo "REJECTED: $test_file — ${ratio}x ratio (${test_lines}L test / ${src_lines}L source)"
    echo "  Solution: Delete unit test. Write integration test instead."
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "Mock tax check passed — no bloated unit tests"
fi

exit $FAIL
