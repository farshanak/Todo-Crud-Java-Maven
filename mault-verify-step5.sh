#!/usr/bin/env bash
set -uo pipefail

# ╔══════════════════════════════════════════════════════════════╗
# ║  MAULT RALPH LOOP — Step 5 TDD Framework Verification       ║
# ║  Physics, not policy. This script checks REAL STATE.         ║
# ║  Exit 0 = all pass. Exit 1 = work remains.                  ║
# ╚══════════════════════════════════════════════════════════════╝

PASS_COUNT=0
FAIL_COUNT=0
PENDING_COUNT=0
CHECK_RESULTS=()

PROOF_DIR=".mault"
PROOF_FILE="$PROOF_DIR/verify-step5.proof"

record_result() { CHECK_RESULTS+=("CHECK $1: $2 - $3"); }
print_pass()    { echo "[PASS]    CHECK $1: $2"; PASS_COUNT=$((PASS_COUNT + 1)); record_result "$1" "PASS" "$2"; }
print_fail()    { echo "[FAIL]    CHECK $1: $2"; FAIL_COUNT=$((FAIL_COUNT + 1)); record_result "$1" "FAIL" "$2"; }
print_pending() { echo "[PENDING] CHECK $1: $2"; PENDING_COUNT=$((PENDING_COUNT + 1)); record_result "$1" "PENDING" "$2"; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: Not a git repository."
  exit 1
fi

DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name' 2>/dev/null || echo "main")

write_proof_file() {
  local sha epoch iso token
  sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  epoch=$(date +%s)
  iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")
  token="MAULT-STEP5-${sha}-${epoch}-9/9"

  mkdir -p "$PROOF_DIR"
  if [ ! -f "$PROOF_DIR/.gitignore" ]; then
    printf '*\n!.gitignore\n' > "$PROOF_DIR/.gitignore"
  fi

  {
    echo "MAULT-STEP5-PROOF"
    echo "=================="
    echo "Timestamp: $epoch"
    echo "DateTime: $iso"
    echo "GitSHA: $sha"
    echo "Checks: 9/9 PASS"
    for r in "${CHECK_RESULTS[@]}"; do
      echo "  $r"
    done
    echo "=================="
    echo "Token: $token"
  } > "$PROOF_FILE"

  echo ""
  echo "Proof file written: $PROOF_FILE"
  echo "Token: $token"
}

check_proof_staleness() {
  if [ -f "$PROOF_FILE" ]; then
    local proof_sha current_sha
    proof_sha=$(grep '^GitSHA:' "$PROOF_FILE" | awk '{print $2}')
    current_sha=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    if [ "$proof_sha" != "$current_sha" ]; then
      echo "WARNING: Proof file is STALE (proof: $proof_sha, HEAD: $current_sha). Deleting."
      rm -f "$PROOF_FILE"
    fi
  fi
}

echo "========================================"
echo "  MAULT Step 5 TDD Framework Verification"
echo "  Detected stack: java"
echo "========================================"
echo ""

# --- CHECK 1: Step 4 Prerequisite + Branch Protection ---

check_1() {
  if [ ! -f ".mault/verify-step4.proof" ]; then
    print_fail 1 "Step 4 not complete. Run mault-verify-step4.sh first."
    return
  fi
  local token
  token=$(grep '^Token:' .mault/verify-step4.proof | awk '{print $2}') || true

  local owner repo
  owner=$(gh repo view --json owner -q '.owner.login' 2>/dev/null) || true
  repo=$(gh repo view --json name -q '.name' 2>/dev/null) || true
  if [ -n "$owner" ] && [ -n "$repo" ]; then
    local enforce_admins approval_count
    enforce_admins=$(gh api "repos/${owner}/${repo}/branches/${DEFAULT_BRANCH}/protection/enforce_admins" -q '.enabled' 2>/dev/null) || true
    approval_count=$(gh api "repos/${owner}/${repo}/branches/${DEFAULT_BRANCH}/protection/required_pull_request_reviews" -q '.required_approving_review_count' 2>/dev/null) || true
    if [ "$enforce_admins" != "true" ]; then
      print_fail 1 "Step 4 proof exists but enforce_admins is OFF."
      return
    fi
    if [ -z "$approval_count" ] || [ "$approval_count" -lt 1 ] 2>/dev/null; then
      print_fail 1 "Step 4 proof exists but PR approvals required is ${approval_count:-0}."
      return
    fi
  fi

  print_pass 1 "Step 4 proof exists (${token:-unknown}), branch protection verified"
}

# --- CHECK 2: Test Directory Pyramid ---

check_2() {
  local missing=""
  local base="src/test/java/com/example/todo"
  for dir in unit integration; do
    if [ ! -d "${base}/${dir}" ]; then
      missing="${missing}${base}/${dir} "
    fi
  done
  if [ ! -d "tests/mocks" ] && [ ! -d "src/test/resources" ]; then
    missing="${missing}src/test/resources "
  fi

  if [ -z "$missing" ]; then
    print_pass 2 "Test directory pyramid exists"
  else
    print_fail 2 "Missing test directories: ${missing}"
  fi
}

# --- CHECK 3: Test Runner Config (Maven + JaCoCo) ---

check_3() {
  if [ -f "pom.xml" ]; then
    if grep -q 'maven-surefire-plugin\|spring-boot-starter-test' pom.xml 2>/dev/null; then
      print_pass 3 "Test runner configuration found (Maven + JUnit)"
    else
      print_fail 3 "No test runner config in pom.xml"
    fi
  else
    print_fail 3 "No pom.xml found"
  fi
}

# --- CHECK 4: Coverage Thresholds (JaCoCo) ---

check_4() {
  if [ -f "pom.xml" ] && grep -q 'jacoco-maven-plugin' pom.xml 2>/dev/null; then
    if grep -q 'COVEREDRATIO\|coveredRatio\|minimum' pom.xml 2>/dev/null; then
      print_pass 4 "Coverage thresholds configured (JaCoCo)"
    else
      print_fail 4 "JaCoCo plugin found but no coverage thresholds set"
    fi
  else
    print_fail 4 "No JaCoCo coverage plugin. Add jacoco-maven-plugin to pom.xml"
  fi
}

# --- CHECK 5: Shared Mock/Test Infrastructure ---

check_5() {
  local found=false
  if ls src/test/java/com/example/todo/mocks/*.java >/dev/null 2>&1; then
    found=true
  fi
  if ls src/test/java/com/example/todo/fixtures/*.java >/dev/null 2>&1; then
    found=true
  fi
  if ls src/test/resources/*.json src/test/resources/*.properties >/dev/null 2>&1; then
    found=true
  fi
  # Also accept tests/mocks for the verification script spec
  if [ -d "tests/mocks" ] && ls tests/mocks/*.java >/dev/null 2>&1; then
    found=true
  fi

  if $found; then
    print_pass 5 "Shared mock/fixture infrastructure exists"
  else
    print_pending 5 "No shared test fixtures. Create test helpers or resources."
  fi
}

# --- CHECK 6: Tests Pass ---

check_6() {
  local output exit_code
  output=$(./mvnw test -B 2>&1)
  exit_code=$?

  if [ "$exit_code" -eq 0 ]; then
    if echo "$output" | grep -qE "Tests run: [1-9]"; then
      print_pass 6 "Tests pass with real tests"
    else
      print_fail 6 "Test runner passed but no tests found."
    fi
  else
    print_fail 6 "Tests failing (exit code: ${exit_code}). Fix tests before proceeding."
  fi
}

# --- CHECK 7: CI Workflow Has Integration Job + Branch Protection ---

check_7() {
  local ci_file
  ci_file=$(ls .github/workflows/ci.yml .github/workflows/ci.yaml 2>/dev/null | head -1) || true

  if [ -z "$ci_file" ]; then
    print_fail 7 "No CI workflow found."
    return
  fi

  if ! grep -qE -- 'integration|Integration' "$ci_file" 2>/dev/null; then
    print_fail 7 "CI workflow missing integration job."
    return
  fi
  if ! grep -qE -- '--coverage|jacoco|verify.*jacoco|JaCoCo' "$ci_file" 2>/dev/null; then
    print_fail 7 "CI workflow missing coverage enforcement in integration job."
    return
  fi

  local owner repo
  owner=$(gh repo view --json owner -q '.owner.login' 2>/dev/null) || true
  repo=$(gh repo view --json name -q '.name' 2>/dev/null) || true
  if [ -n "$owner" ] && [ -n "$repo" ]; then
    local protection
    protection=$(gh api "repos/${owner}/${repo}/branches/${DEFAULT_BRANCH}/protection/required_status_checks" -q '.contexts[]' 2>/dev/null) || true
    if [ -n "$protection" ]; then
      if ! echo "$protection" | grep -qiF "integration" 2>/dev/null; then
        print_fail 7 "Integration job exists in CI but is NOT a required branch protection check."
        return
      fi
    fi
  fi

  print_pass 7 "CI has integration job with coverage, required in branch protection"
}

# --- CHECK 8: TIA Script ---

check_8() {
  local found=false
  if [ -f "Makefile" ] && grep -q 'test-tia' Makefile 2>/dev/null; then
    found=true
  fi
  if [ -f "scripts/test-impact-analysis.sh" ]; then
    found=true
  fi

  if $found; then
    print_pass 8 "TIA (Test Impact Analysis) script configured"
  else
    print_fail 8 "No TIA script. Add test-tia to Makefile (see Phase 6)"
  fi
}

# --- CHECK 9: Handshake Issue ---

check_9() {
  if ! command -v gh >/dev/null 2>&1; then
    print_pending 9 "GitHub CLI not available."
    return
  fi

  local issue_url
  issue_url=$(gh issue list --search "[MAULT] Production Readiness: Step 5" --json url -q '.[0].url' 2>/dev/null) || true
  if [ -z "$issue_url" ]; then
    issue_url=$(gh issue list --state closed --search "[MAULT] Production Readiness: Step 5" --json url -q '.[0].url' 2>/dev/null) || true
  fi

  if [ -n "$issue_url" ]; then
    print_pass 9 "Handshake issue: ${issue_url}"
  else
    print_pending 9 "No handshake issue found. Create it as proof of completion."
  fi
}

check_proof_staleness
check_1
check_2
check_3
check_4
check_5
check_6
check_7
check_8
check_9

echo ""
echo "========================================"
echo "  PASS: ${PASS_COUNT}/9  FAIL: ${FAIL_COUNT}/9  PENDING: ${PENDING_COUNT}/9"
echo "========================================"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$PENDING_COUNT" -eq 0 ]; then
  write_proof_file
  echo "ALL CHECKS PASSED. Step 5 TDD Framework is complete."
  exit 0
elif [ "$FAIL_COUNT" -gt 0 ]; then
  rm -f "$PROOF_FILE"
  echo "${FAIL_COUNT} check(s) FAILED. Fix and re-run: ./mault-verify-step5.sh"
  exit 1
else
  rm -f "$PROOF_FILE"
  echo "${PENDING_COUNT} check(s) PENDING. Complete work and re-run: ./mault-verify-step5.sh"
  exit 1
fi
