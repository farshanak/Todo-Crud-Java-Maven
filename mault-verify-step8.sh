#!/usr/bin/env bash
# mault-verify-step8.sh — Ralph Loop verification for Step 8: Governance Testing
# 10 CHECKs. Exit 0 only if ALL pass.
set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0
PENDING_COUNT=0
CHECK_RESULTS=()
TOTAL_CHECKS=10

PROOF_DIR=".mault"
PROOF_FILE="$PROOF_DIR/verify-step8.proof"

record_result() { CHECK_RESULTS+=("CHECK $1: $2 - $3"); }
print_pass()    { echo "[PASS]    CHECK $1: $2"; PASS_COUNT=$((PASS_COUNT + 1)); record_result "$1" "PASS" "$2"; }
print_fail()    { echo "[FAIL]    CHECK $1: $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); record_result "$1" "FAIL" "$2"; }
print_pending() { echo "[PENDING] CHECK $1: $2"; PENDING_COUNT=$((PENDING_COUNT + 1)); record_result "$1" "PENDING" "$2"; }

if [ -f "$PROOF_FILE" ]; then
  PROOF_SHA=$(grep '^GitSHA:' "$PROOF_FILE" | awk '{print $2}')
  CURRENT_SHA=$(git rev-parse --short HEAD 2>/dev/null)
  if [ "$PROOF_SHA" != "$CURRENT_SHA" ]; then
    rm -f "$PROOF_FILE"
  fi
fi

DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null || echo "main")

echo "========================================"
echo "  MAULT Step 8 Governance Verification"
echo "  Default branch: $DEFAULT_BRANCH"
echo "========================================"
echo ""

# CHECK 1: Step 7 prerequisite
check_1() {
  if [ -f ".mault/verify-step7.proof" ]; then
    local token
    token=$(grep '^Token:' .mault/verify-step7.proof | awk '{print $2}') || true
    print_pass 1 "Step 7 proof exists (${token:-unknown})"
  else
    print_fail 1 "Step 7 not complete."
  fi
}

# CHECK 2: Governance scripts exist
check_2() {
  local missing=""
  for script in check-silent-catches.sh check-mock-tax.sh guardrails-check.sh check-skipped-tests.sh verify-integration-pairing.sh collect-metrics.sh check-duplicate-code.sh check-security-critical.sh; do
    if [ ! -f "scripts/governance/$script" ]; then
      missing="${missing}${script} "
    fi
  done
  if [ -z "$missing" ]; then
    local count
    count=$(ls scripts/governance/*.sh 2>/dev/null | wc -l | tr -d ' ')
    print_pass 2 "All ${count} governance scripts exist"
  else
    print_fail 2 "Missing scripts: ${missing}"
  fi
}

# CHECK 3: Governance scripts pass
check_3() {
  local fail=0
  for script in scripts/governance/guardrails-check.sh scripts/governance/check-skipped-tests.sh scripts/governance/verify-integration-pairing.sh scripts/governance/check-mock-tax.sh; do
    if [ -f "$script" ]; then
      bash "$script" > /dev/null 2>&1
      if [ $? -ne 0 ]; then
        echo "  FAILED: $script"
        fail=1
      fi
    fi
  done
  if [ "$fail" -eq 0 ]; then
    print_pass 3 "All governance scripts pass"
  else
    print_fail 3 "Some governance scripts failing"
  fi
}

# CHECK 4: Baselines exist
check_4() {
  local count
  count=$(ls .memory-layer/baselines/*.json 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -ge 3 ]; then
    print_pass 4 "Ratchet baselines exist (${count} files)"
  else
    print_fail 4 "Need at least 3 baseline files, found ${count}"
  fi
}

# CHECK 5: Governance manifest exists
check_5() {
  if [ -f ".mault/governance-manifest.json" ]; then
    print_pass 5 "Governance manifest exists"
  else
    print_fail 5 "Missing .mault/governance-manifest.json"
  fi
}

# CHECK 6: Pre-commit has governance hooks
check_6() {
  if [ ! -f ".pre-commit-config.yaml" ]; then
    print_fail 6 "No pre-commit config"
    return
  fi
  local gov_hooks
  gov_hooks=$(grep -c 'governance/' .pre-commit-config.yaml 2>/dev/null || echo 0)
  if [ "$gov_hooks" -ge 3 ]; then
    print_pass 6 "Pre-commit config has ${gov_hooks} governance hooks"
  else
    print_fail 6 "Pre-commit needs at least 3 governance hooks, found ${gov_hooks}"
  fi
}

# CHECK 7: CI has governance job
check_7() {
  local ci_file
  ci_file=$(ls .github/workflows/ci.yml .github/workflows/ci.yaml 2>/dev/null | head -1) || true
  if [ -z "$ci_file" ]; then
    print_fail 7 "No CI workflow"
    return
  fi
  if grep -q 'governance:' "$ci_file" 2>/dev/null; then
    print_pass 7 "CI has governance job"
  else
    print_fail 7 "CI missing governance job"
  fi
}

# CHECK 8: Gitleaks config exists
check_8() {
  if [ -f ".gitleaks.toml" ]; then
    print_pass 8 "Gitleaks config exists"
  else
    print_fail 8 "Missing .gitleaks.toml"
  fi
}

# CHECK 9: Merged PR for Step 8
check_9() {
  local merged_url
  merged_url=$(gh pr list --state merged --search "step8 OR governance" --limit 1 --json url -q '.[0].url' 2>/dev/null) || true
  if [ -n "$merged_url" ]; then
    print_pass 9 "Merged PR found: ${merged_url}"
    return
  fi
  local open_url
  open_url=$(gh pr list --state open --search "step8 OR governance" --limit 1 --json url -q '.[0].url' 2>/dev/null) || true
  if [ -n "$open_url" ]; then
    print_pending 9 "PR exists but not merged: ${open_url}"
  else
    print_pending 9 "No Step 8 PR found"
  fi
}

# CHECK 10: Handshake issue
check_10() {
  local issue_url
  issue_url=$(gh issue list --search "[MAULT] Production Readiness: Step 8" --json url -q '.[0].url' 2>/dev/null) || true
  if [ -z "$issue_url" ]; then
    issue_url=$(gh issue list --state closed --search "[MAULT] Production Readiness: Step 8" --json url -q '.[0].url' 2>/dev/null) || true
  fi
  if [ -n "$issue_url" ]; then
    print_pass 10 "Handshake issue: ${issue_url}"
  else
    print_pending 10 "No handshake issue found"
  fi
}

check_1; check_2; check_3; check_4; check_5; check_6; check_7; check_8; check_9; check_10

echo ""
echo "========================================"
echo "  PASS: ${PASS_COUNT}/${TOTAL_CHECKS}  FAIL: ${FAIL_COUNT}/${TOTAL_CHECKS}  PENDING: ${PENDING_COUNT}/${TOTAL_CHECKS}"
echo "========================================"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$PENDING_COUNT" -eq 0 ]; then
  sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  epoch=$(date +%s)
  iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")
  token="MAULT-STEP8-${sha}-${epoch}-${TOTAL_CHECKS}/${TOTAL_CHECKS}"

  mkdir -p "$PROOF_DIR"
  if [ ! -f "$PROOF_DIR/.gitignore" ]; then
    printf '*\n!.gitignore\n' > "$PROOF_DIR/.gitignore"
  fi

  {
    echo "MAULT-STEP8-PROOF"
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
  echo "ALL CHECKS PASSED. Step 8 Governance Testing is complete."
  exit 0
elif [ "$FAIL_COUNT" -gt 0 ]; then
  rm -f "$PROOF_FILE"
  echo "${FAIL_COUNT} check(s) FAILED. Fix and re-run: ./mault-verify-step8.sh"
  exit 1
else
  rm -f "$PROOF_FILE"
  echo "${PENDING_COUNT} check(s) PENDING. Complete work and re-run: ./mault-verify-step8.sh"
  exit 1
fi
