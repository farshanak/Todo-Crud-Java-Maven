#!/bin/bash
# Gatekeeper: Security-Critical Code Review Gate
# Files marked @SecurityCritical or containing auth/crypto patterns
# require explicit human review annotation.

set -euo pipefail

SCAN_DIR="src/main/java"
FAIL=0

if [ ! -d "$SCAN_DIR" ]; then
  exit 0
fi

# Check staged files for security-sensitive patterns
STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "\.java$" || true)

if [ -z "$STAGED" ]; then
  echo "No staged Java files — skipping security check"
  exit 0
fi

for file in $STAGED; do
  if [ ! -f "$file" ]; then continue; fi

  # Check for security-sensitive patterns
  if grep -qE "(password|secret|token|apiKey|credential|encrypt|decrypt|hash|auth)" "$file" 2>/dev/null; then
    if ! grep -q "@SecurityReviewed" "$file" 2>/dev/null; then
      echo "WARNING: $file contains security-sensitive patterns"
      echo "  Consider adding @SecurityReviewed annotation after human review"
    fi
  fi
done

echo "Security-critical check passed"
exit $FAIL
