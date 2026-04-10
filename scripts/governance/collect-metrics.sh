#!/bin/bash
# Governance Metrics Collection
# Collects and reports governance health metrics.

set -euo pipefail

SRC_DIR="src/main/java"
TEST_DIR="src/test/java"

echo "========================================"
echo "  Governance Metrics Report"
echo "  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "========================================"

# Source metrics
SRC_FILES=$(find "$SRC_DIR" -name "*.java" -type f 2>/dev/null | wc -l | tr -d ' ')
SRC_LINES=$(find "$SRC_DIR" -name "*.java" -type f -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
echo "Source files: $SRC_FILES"
echo "Source LOC: $SRC_LINES"

# Test metrics
TEST_FILES=$(find "$TEST_DIR" -name "*.java" -type f 2>/dev/null | wc -l | tr -d ' ')
TEST_LINES=$(find "$TEST_DIR" -name "*.java" -type f -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
TEST_COUNT=$(grep -r "@Test" "$TEST_DIR" --include="*.java" -c 2>/dev/null || echo 0)
echo "Test files: $TEST_FILES"
echo "Test LOC: $TEST_LINES"
echo "Test count: $TEST_COUNT"

# Ratios
if [ "$SRC_LINES" -gt 0 ]; then
  RATIO=$(echo "scale=1; $TEST_LINES / $SRC_LINES" | bc 2>/dev/null || echo "N/A")
  echo "Test/Source ratio: ${RATIO}x"
fi

# Quality metrics
DISABLED=$(grep -r "@Disabled" "$TEST_DIR" --include="*.java" -c 2>/dev/null || echo 0)
SILENT_CATCHES=$(find "$SRC_DIR" -name "*.java" -exec grep -lP 'catch\s*\([^)]*\)\s*\{[\s]*\}' {} + 2>/dev/null | wc -l | tr -d ' ')
echo "Disabled tests: $DISABLED"
echo "Silent catches: $SILENT_CATCHES"

echo "========================================"
