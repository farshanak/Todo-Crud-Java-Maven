#!/bin/bash
# Buddy System: Integration Test Pairing
# Every controller must have a corresponding integration test.

set -euo pipefail

SRC_DIR="src/main/java/com/example/todo/controller"
TEST_DIR="src/test/java/com/example/todo/integration"
FAIL=0

if [ ! -d "$SRC_DIR" ]; then
  echo "No controller directory — skipping"
  exit 0
fi

for src_file in $(find "$SRC_DIR" -name "*Controller.java" -type f 2>/dev/null); do
  name=$(basename "$src_file" .java)
  expected_test="${TEST_DIR}/${name}IntegrationTest.java"

  if [ ! -f "$expected_test" ]; then
    echo "MISSING: Integration test for $name"
    echo "  Expected: $expected_test"
    FAIL=1
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "Integration test pairing passed — all controllers have integration tests"
fi

exit $FAIL
