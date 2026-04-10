#!/bin/bash
FAIL=0
for f in $(git diff --cached --name-only --diff-filter=ACM | grep "\.java$" | grep -v "src/test"); do
  LINES=$(wc -l < "$f" | tr -d " ")
  if [ "$LINES" -gt 600 ]; then
    echo "FAIL: $f has $LINES lines (max 600)"
    FAIL=1
  elif [ "$LINES" -gt 300 ]; then
    echo "WARN: $f has $LINES lines (consider splitting at 300)"
  fi
done
exit $FAIL
