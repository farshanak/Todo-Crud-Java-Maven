#!/usr/bin/env bash
# mault-verify-step7.sh — Ralph Loop verification for Step 7: Mault Enforcement
# 8 CHECKs. Exit 0 only if ALL pass.
set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0
PENDING_COUNT=0
CHECK_RESULTS=()
TOTAL_CHECKS=8

PROOF_DIR=".mault"
PROOF_FILE="$PROOF_DIR/verify-step7.proof"

record_result() { CHECK_RESULTS+=("CHECK $1: $2 - $3"); }
print_pass()    { echo "[PASS]    CHECK $1: $2"; PASS_COUNT=$((PASS_COUNT + 1)); record_result "$1" "PASS" "$2"; }
print_fail()    { echo "[FAIL]    CHECK $1: $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); record_result "$1" "FAIL" "$2"; }
print_pending() { echo "[PENDING] CHECK $1: $2"; PENDING_COUNT=$((PENDING_COUNT + 1)); record_result "$1" "PENDING" "$2"; }

if [ -f "$PROOF_FILE" ]; then
  PROOF_SHA=$(grep '^GitSHA:' "$PROOF_FILE" | awk '{print $2}')
  CURRENT_SHA=$(git rev-parse --short HEAD 2>/dev/null)
  if [ "$PROOF_SHA" != "$CURRENT_SHA" ]; then
    echo "Stale proof detected. Deleting."
    rm -f "$PROOF_FILE"
  fi
fi

DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null || echo "main")

echo "========================================"
echo "  MAULT Step 7 Enforcement Verification"
echo "  Default branch: $DEFAULT_BRANCH"
echo "========================================"
echo ""

# CHECK 1: Step 6 prerequisite
check_1() {
  if [ -f ".mault/verify-step6.proof" ]; then
    local token
    token=$(grep '^Token:' .mault/verify-step6.proof | awk '{print $2}') || true
    print_pass 1 "Step 6 proof exists (${token:-unknown})"
  else
    print_fail 1 "Step 6 not complete."
  fi
}

# CHECK 2: docs/mault.yaml exists and has required sections
check_2() {
  if [ ! -f "docs/mault.yaml" ]; then
    print_fail 2 "docs/mault.yaml not found"
    return
  fi
  local has_detectors has_conventions has_deprecated
  has_detectors=$(grep -c '^Detectors:' docs/mault.yaml 2>/dev/null) || true
  has_conventions=$(grep -c 'conventions:' docs/mault.yaml 2>/dev/null) || true
  has_deprecated=$(grep -c 'deprecatedPatterns:' docs/mault.yaml 2>/dev/null) || true

  if [ "$has_detectors" -gt 0 ] && [ "$has_conventions" -gt 0 ] && [ "$has_deprecated" -gt 0 ]; then
    print_pass 2 "docs/mault.yaml has Detectors, conventions, and deprecatedPatterns"
  else
    local missing=""
    [ "$has_detectors" -eq 0 ] && missing="${missing}Detectors "
    [ "$has_conventions" -eq 0 ] && missing="${missing}conventions "
    [ "$has_deprecated" -eq 0 ] && missing="${missing}deprecatedPatterns "
    print_fail 2 "docs/mault.yaml missing sections: ${missing}"
  fi
}

# CHECK 3: All 9 polyglot detectors configured
check_3() {
  if [ ! -f "docs/mault.yaml" ]; then
    print_fail 3 "docs/mault.yaml not found"
    return
  fi
  local missing=""
  for uc in UC01 UC02 UC04 UC05 UC06 UC07 UC08 UC09 UC11; do
    if ! grep -q "$uc:" docs/mault.yaml 2>/dev/null; then
      missing="${missing}${uc} "
    fi
  done
  if [ -z "$missing" ]; then
    print_pass 3 "All 9 polyglot detectors configured (UC01-UC11)"
  else
    print_fail 3 "Missing detectors: ${missing}"
  fi
}

# CHECK 4: Ratchet baselines exist
check_4() {
  local missing=""
  if [ ! -f ".memory-layer/baselines/coverage.json" ]; then
    missing="${missing}coverage.json "
  fi
  if [ ! -f ".memory-layer/baselines/file-count.json" ]; then
    missing="${missing}file-count.json "
  fi
  if [ -z "$missing" ]; then
    print_pass 4 "Ratchet baselines exist (coverage, file-count)"
  else
    print_fail 4 "Missing baselines: ${missing}"
  fi
}

# CHECK 5: All tests still pass
check_5() {
  local output exit_code
  output=$(./mvnw test -B 2>&1)
  exit_code=$?
  if [ "$exit_code" -eq 0 ]; then
    print_pass 5 "All tests pass"
  else
    print_fail 5 "Tests failing (exit $exit_code)"
  fi
}

# CHECK 6: Merged PR for Step 7
check_6() {
  local merged_url
  merged_url=$(gh pr list --state merged --search "step7 OR enforcement OR mault.yaml" --limit 1 --json url -q '.[0].url' 2>/dev/null) || true
  if [ -n "$merged_url" ]; then
    print_pass 6 "Merged PR found: ${merged_url}"
    return
  fi
  local open_url
  open_url=$(gh pr list --state open --search "step7 OR enforcement OR mault.yaml" --limit 1 --json url -q '.[0].url' 2>/dev/null) || true
  if [ -n "$open_url" ]; then
    print_pending 6 "PR exists but not merged: ${open_url}"
  else
    print_pending 6 "No Step 7 PR found"
  fi
}

# CHECK 7: Handshake issue
check_7() {
  local issue_url
  issue_url=$(gh issue list --search "[MAULT] Production Readiness: Step 7" --json url -q '.[0].url' 2>/dev/null) || true
  if [ -z "$issue_url" ]; then
    issue_url=$(gh issue list --state closed --search "[MAULT] Production Readiness: Step 7" --json url -q '.[0].url' 2>/dev/null) || true
  fi
  if [ -n "$issue_url" ]; then
    print_pass 7 "Handshake issue: ${issue_url}"
  else
    print_pending 7 "No handshake issue found"
  fi
}

# CHECK 8: CI still green on default branch
check_8() {
  local run_info status conclusion
  run_info=$(gh run list --branch "$DEFAULT_BRANCH" --limit 1 --json status,conclusion \
    -q '.[0] | "\(.status)|\(.conclusion)"' 2>/dev/null) || true
  if [ -z "$run_info" ]; then
    print_pending 8 "No CI runs on $DEFAULT_BRANCH"
    return
  fi
  status=$(echo "$run_info" | cut -d'|' -f1)
  conclusion=$(echo "$run_info" | cut -d'|' -f2)
  if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
    print_pass 8 "Latest CI on $DEFAULT_BRANCH is green"
  elif [ "$status" = "in_progress" ] || [ "$status" = "queued" ]; then
    print_pending 8 "CI is ${status} — wait and re-run"
  else
    print_fail 8 "Latest CI on $DEFAULT_BRANCH failed (${conclusion})"
  fi
}

check_1; check_2; check_3; check_4; check_5; check_6; check_7; check_8

echo ""
echo "========================================"
echo "  PASS: ${PASS_COUNT}/${TOTAL_CHECKS}  FAIL: ${FAIL_COUNT}/${TOTAL_CHECKS}  PENDING: ${PENDING_COUNT}/${TOTAL_CHECKS}"
echo "========================================"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$PENDING_COUNT" -eq 0 ]; then
  sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  epoch=$(date +%s)
  iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")
  token="MAULT-STEP7-${sha}-${epoch}-${TOTAL_CHECKS}/${TOTAL_CHECKS}"

  mkdir -p "$PROOF_DIR"
  if [ ! -f "$PROOF_DIR/.gitignore" ]; then
    printf '*\n!.gitignore\n' > "$PROOF_DIR/.gitignore"
  fi

  {
    echo "MAULT-STEP7-PROOF"
    echo "=================="
    echo "Timestamp: $epoch"
    echo "DateTime: $iso"
    echo "GitSHA: $sha"
    echo "Checks: ${TOTAL_CHECKS}/${TOTAL_CHECKS} PASS"
    for r in "${CHECK_RESULTS[@]}"; do
      echo "  $r"
    done
    echo "=================="
    echo "Token: $token"
  } > "$PROOF_FILE"

  echo ""
  echo "Proof file written: $PROOF_FILE"
  echo "Token: $token"
  echo "ALL CHECKS PASSED. Step 7 Mault Enforcement is complete."
  exit 0
elif [ "$FAIL_COUNT" -gt 0 ]; then
  rm -f "$PROOF_FILE"
  echo "${FAIL_COUNT} check(s) FAILED. Fix and re-run: ./mault-verify-step7.sh"
  exit 1
else
  rm -f "$PROOF_FILE"
  echo "${PENDING_COUNT} check(s) PENDING. Complete work and re-run: ./mault-verify-step7.sh"
  exit 1
fi
