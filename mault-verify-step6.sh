#!/usr/bin/env bash
# mault-verify-step6.sh — Ralph Loop verification for Step 6: Pre-commit Hooks
# 12 CHECKs. Exit 0 only if ALL pass.
set -uo pipefail

PASS_COUNT=0
FAIL_COUNT=0
PENDING_COUNT=0
CHECK_RESULTS=()
TOTAL_CHECKS=12

PROOF_DIR=".mault"
PROOF_FILE="$PROOF_DIR/verify-step6.proof"

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

detect_default_branch() {
  local branch
  branch=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null) || true
  if [ -n "$branch" ]; then echo "$branch"; return; fi
  if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then echo "main"
  elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then echo "master"
  else echo "main"; fi
}
DEFAULT_BRANCH=$(detect_default_branch)

echo "========================================"
echo "  MAULT Step 6 Pre-commit Verification"
echo "  Default branch: $DEFAULT_BRANCH"
echo "========================================"
echo ""

# CHECK 1: Step 5 prerequisite
check_1() {
  if [ -f ".mault/verify-step5.proof" ]; then
    local token
    token=$(grep '^Token:' .mault/verify-step5.proof | awk '{print $2}') || true
    print_pass 1 "Step 5 proof exists (${token:-unknown})"
  else
    print_fail 1 "Step 5 not complete."
  fi
}

# CHECK 2: pre-commit CLI installed
check_2() {
  if command -v pre-commit >/dev/null 2>&1; then
    local ver
    ver=$(pre-commit --version 2>&1)
    print_pass 2 "pre-commit installed ($ver)"
  else
    print_fail 2 "pre-commit not installed"
  fi
}

# CHECK 3: Config file exists
check_3() {
  if [ -f ".pre-commit-config.yaml" ]; then
    print_pass 3 "pre-commit config exists"
  else
    print_fail 3 "Missing .pre-commit-config.yaml"
  fi
}

# CHECK 4: Git hook installed
check_4() {
  if [ -f ".git/hooks/pre-commit" ] && [ -x ".git/hooks/pre-commit" ]; then
    print_pass 4 "Git pre-commit hook installed and executable"
  else
    print_fail 4 "Git pre-commit hook not installed. Run: pre-commit install"
  fi
}

# CHECK 5: Hooks pass on all files
check_5() {
  local output exit_code
  output=$(pre-commit run --all-files 2>&1)
  exit_code=$?
  if [ "$exit_code" -eq 0 ]; then
    print_pass 5 "All pre-commit hooks pass"
  else
    print_fail 5 "Pre-commit hooks failing. Run: pre-commit run --all-files"
  fi
}

# CHECK 6: Branch name validation script exists
check_6() {
  if [ -f "scripts/check-branch-name.sh" ]; then
    print_pass 6 "Branch name validation script exists"
  else
    print_fail 6 "Missing scripts/check-branch-name.sh"
  fi
}

# CHECK 7: CI has validate-pr-title job
check_7() {
  local ci_file
  ci_file=$(ls .github/workflows/ci.yml .github/workflows/ci.yaml 2>/dev/null | head -1) || true
  if [ -z "$ci_file" ]; then
    print_fail 7 "No CI workflow found"
    return
  fi
  if grep -q 'validate-pr-title' "$ci_file" 2>/dev/null; then
    print_pass 7 "CI has validate-pr-title job"
  else
    print_fail 7 "CI missing validate-pr-title job"
  fi
}

# CHECK 8: CI has validate-branch-name job
check_8() {
  local ci_file
  ci_file=$(ls .github/workflows/ci.yml .github/workflows/ci.yaml 2>/dev/null | head -1) || true
  if [ -z "$ci_file" ]; then
    print_fail 8 "No CI workflow found"
    return
  fi
  if grep -q 'validate-branch-name' "$ci_file" 2>/dev/null; then
    print_pass 8 "CI has validate-branch-name job"
  else
    print_fail 8 "CI missing validate-branch-name job"
  fi
}

# CHECK 9: Branch protection includes new checks
check_9() {
  local owner repo
  owner=$(gh repo view --json owner -q '.owner.login' 2>/dev/null) || true
  repo=$(gh repo view --json name -q '.name' 2>/dev/null) || true
  if [ -z "$owner" ] || [ -z "$repo" ]; then
    print_fail 9 "Cannot determine repo"
    return
  fi
  local protection
  protection=$(gh api "repos/${owner}/${repo}/branches/${DEFAULT_BRANCH}/protection/required_status_checks" -q '.contexts[]' 2>/dev/null) || true
  if [ -z "$protection" ]; then
    print_fail 9 "No branch protection configured"
    return
  fi
  local missing=""
  echo "$protection" | grep -qF "validate-pr-title" || missing="${missing}validate-pr-title "
  echo "$protection" | grep -qF "validate-branch-name" || missing="${missing}validate-branch-name "
  if [ -z "$missing" ]; then
    print_pass 9 "Branch protection includes validate-pr-title and validate-branch-name"
  else
    print_fail 9 "Branch protection missing: ${missing}"
  fi
}

# CHECK 10: Handshake commit exists
check_10() {
  if git log --oneline --all | grep -q '\[mault-step6\]'; then
    print_pass 10 "Handshake commit with [mault-step6] found"
  else
    print_pending 10 "No commit with [mault-step6] marker found"
  fi
}

# CHECK 11: Merged PR with passing checks
check_11() {
  local merged_url
  merged_url=$(gh pr list --state merged --search "step6" --limit 1 --json url -q '.[0].url' 2>/dev/null) || true
  if [ -n "$merged_url" ]; then
    print_pass 11 "Merged PR found: ${merged_url}"
    return
  fi
  local open_url
  open_url=$(gh pr list --state open --search "step6" --limit 1 --json url -q '.[0].url' 2>/dev/null) || true
  if [ -n "$open_url" ]; then
    print_pending 11 "PR exists but not merged: ${open_url}"
  else
    print_pending 11 "No Step 6 PR found"
  fi
}

# CHECK 12: Handshake issue
check_12() {
  local issue_url
  issue_url=$(gh issue list --search "[MAULT] Production Readiness: Step 6" --json url -q '.[0].url' 2>/dev/null) || true
  if [ -z "$issue_url" ]; then
    issue_url=$(gh issue list --state closed --search "[MAULT] Production Readiness: Step 6" --json url -q '.[0].url' 2>/dev/null) || true
  fi
  if [ -n "$issue_url" ]; then
    print_pass 12 "Handshake issue: ${issue_url}"
  else
    print_pending 12 "No handshake issue found"
  fi
}

check_1; check_2; check_3; check_4; check_5; check_6
check_7; check_8; check_9; check_10; check_11; check_12

echo ""
echo "========================================"
echo "  PASS: ${PASS_COUNT}/${TOTAL_CHECKS}  FAIL: ${FAIL_COUNT}/${TOTAL_CHECKS}  PENDING: ${PENDING_COUNT}/${TOTAL_CHECKS}"
echo "========================================"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$PENDING_COUNT" -eq 0 ]; then
  local sha epoch iso token
  sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  epoch=$(date +%s)
  iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")
  token="MAULT-STEP6-${sha}-${epoch}-${TOTAL_CHECKS}/${TOTAL_CHECKS}"

  mkdir -p "$PROOF_DIR"
  if [ ! -f "$PROOF_DIR/.gitignore" ]; then
    printf '*\n!.gitignore\n' > "$PROOF_DIR/.gitignore"
  fi

  {
    echo "MAULT-STEP6-PROOF"
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
  echo "ALL CHECKS PASSED. Step 6 Pre-commit is complete."
  exit 0
elif [ "$FAIL_COUNT" -gt 0 ]; then
  rm -f "$PROOF_FILE"
  echo "${FAIL_COUNT} check(s) FAILED. Fix and re-run: ./mault-verify-step6.sh"
  exit 1
else
  rm -f "$PROOF_FILE"
  echo "${PENDING_COUNT} check(s) PENDING. Complete work and re-run: ./mault-verify-step6.sh"
  exit 1
fi
