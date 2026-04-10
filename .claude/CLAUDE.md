<!-- mault-hooks-scaffold-v1 -->
<!--
╔══════════════════════════════════════════════════════════════════════╗
║  MAULT PRO - Multi-Agent Orchestration                               ║
║  Copyright © 2025 Mault. All rights reserved.                        ║
║                                                                      ║
║  This document is licensed for use with the Mault VS Code Extension. ║
║  Redistribution or resale is prohibited.                             ║
║                                                                      ║
║  https://mault.dev | support@mault.dev                               ║
╚══════════════════════════════════════════════════════════════════════╝
-->

# CLAUDE.md — Multi-Agent Governance

> Physics, not policy. These rules are enforced by runtime hooks — violations are blocked, not warned.

---

## Roles & Permissions

| Role | Write Code? | Merge? | Zone/Budget? |
|------|-------------|--------|--------------|
| Planner | No | No | N/A (read-only) |
| Orchestrator | No | No | N/A (creates issues) |
| Worker | Yes | No | Yes (enforced) |
| Review Agent | No | Yes | N/A (reviews only) |
| Tester | No | No | N/A (runs tests) |
| Supervisor | Yes | No | No (escalation) |
| Universal | Yes | Yes | No (unrestricted) |

---

## Git Workflow

- **One branch = one PR = one merge.** Never reuse branches or stack PRs.
- Branch naming: `feat/<issue>-<desc>`, `fix/<issue>-<desc>`
- Workers NEVER push to main or merge PRs
- Review Agent merges when ALL CI passes (`gh pr merge --squash`)
- NEVER use `--no-verify` to bypass pre-commit hooks
- NEVER force push to shared branches
- NEVER amend commits already pushed to remote

---

## Labels (Communication Protocol)

| Label | Meaning | Set By |
|-------|---------|--------|
| `mault-ready` | PR ready for review | Worker |
| `mault-needs-fix` | CI failed, fix required | Review Agent |
| `mault-escalation` | Blocked — human needed | Worker (3 strikes) |
| `mault-zone-active` | Zone claimed by worker | Worker |
| `mault-agent` | Task created by orchestrator | Orchestrator |

---

## Key Conventions

### Three Strikes Rule

If blocked by the same governance check 3 times on the same task:
1. STOP — do not keep retrying
2. Add `mault-escalation` label with strike details
3. Release zone and move to next task

### Receipt Protocol

Workers post a receipt before session ends:
```
MAULT-TASK-<issue>-<sha>-<checks>/<total>-<timestamp>
MAULT-TASK-<issue>-<sha>-<checks>/<total>-<timestamp> | ws-<id>-agent-<n>
```
The second form shows the optional workspace/agent suffix accepted by the receipt gate.

### Zone Enforcement

Workers declare a zone (file paths) per task via `.mault/current-task.json`. Runtime hooks block writes outside the zone. One zone = one owner at a time.

### Budget Enforcement

Each task declares max files and max LOC. PostToolUse hooks block writes that exceed budget.

### Fix-First Protocol

Workers must fix broken PRs (`mault-needs-fix`) before pulling new tasks.

---

## Hook Manifest (47 hooks)

### SessionStart (6 hooks)

| Hook | Purpose |
|------|---------|
| hooks-health-check | Warn when settings.local.json drops hooks |
| session-test-rules | Inject testing pyramid rules into context |
| agent-bootstrap | Determine role from preauth, load role state |
| tester-preflight | Generate sprint manifest for tester role |
| compliance-preflight | Inject compliance questionnaire |
| worker-queue-gate | Validate sequence deps and single assignee |

### PreToolUse (26 hooks)

| Hook | Matcher | Purpose |
|------|---------|---------|
| queue-block-enforcer | Write\|Edit\|Bash | Deny all actions when .blocked.json exists |
| pre-write-test-gate | Write | Block source creation without existing test |
| zone-boundary-gate | Write\|Edit | Block writes outside declared zone |
| role-write-gate | Write\|Edit | Role-based file write restrictions |
| orchestrator-file-guard | Write\|Edit | Block orchestrator writes outside .mault/ |
| step-complete-gate | Write\|Edit\|Bash | Validate completion requirements per role |
| worktree-cwd-gate | Bash | Enforce worktree CWD for git commands |
| worktree-occupancy-gate | Bash | Block entry into occupied worktrees |
| role-permission-gate | Bash | Role-based command enforcement |
| sprint-label-gate | Bash | Block mault-agent label on out-of-sprint issues |
| sprint-activation-gate | Bash | Block sprint activation with unresolved deps |
| sprint-scope-gate | Bash | Warn on mid-sprint scope expansion |
| sprint-capacity-gate | Bash | Hard cap of 60 tasks per sprint lifetime |
| sprint-completion-gate | Bash | Hard-stop when sprint queue is empty |
| phase-gate | Bash | Enforce phase-appropriate commands per role |
| bot-arrival-gate | Bash | Block merge until bot checks complete |
| review-comment-gate | Bash | Block merge with unresolved review threads |
| pr-compliance-gate | Bash | Block PR creation unless 7 checks pass |
| review-merge-gate | Bash | Block merge without BOT-TRIAGE-COMPLETE |
| planner-debt-gate | Bash | Block planning with unresolved bot debt |
| issue-claim-gate | Bash | Block zone claim with unsatisfied deps or duplicate assignment |
| dependency-merge-gate | Bash | Block merge when dep issues aren't closed |
| write-preflight-stamp | Bash | Run tests/tsc/lint and write stamp file |
| precommit-install-gate | Bash | Auto-install pre-commit hooks before commit |
| orchestrator-issue-gate | Bash | Validate issue creation has MAULT-META |
| orchestrator-coordination-gate | Bash | Enforce cross-workstation coordination |

### PostToolUse (4 hooks)

| Hook | Matcher | Purpose |
|------|---------|---------|
| post-write-monolith-gate | Write\|Edit | Enforce file size limits and SRP |
| budget-gate | Write\|Edit | Enforce file count and LOC budget |
| post-write-hardcode-gate | Write\|Edit | Detect hard-coded values |
| session-degradation-post | *(all)* | Track session degradation signals |

### Stop (11 hooks)

| Hook | Purpose |
|------|---------|
| planner-completion-gate | Require step-complete.json before planner exit |
| receipt-gate | Require receipt posted before worker exit |
| worktree-release | Detach HEAD in worktree on session exit |
| zone-release-gate | Auto-release mault-zone-active label |
| tester-completion-gate | Require mutation report before tester exit |
| compliance-completion-gate | Require compliance report before exit |
| orchestrator-completion-gate | Validate plan archive and delegation map |
| review-completion-gate | Require Sentry check for merged PRs |
| scenario-gate | Require E2E scenario tests for features |
| stop-test-gate | Verify tests exist for all new source files |
| universal-worktree-cleanup | Clean up universal agent worktrees on exit |

---

## Test Convention

| Key | Value |
|-----|-------|
| source root | src/main/java/ |
| test root | src/test/java/ |
| test file pattern | {name}Test.java |

---

## Language Adaptation

### Language-Coupled Modules

These hooks contain language-specific patterns and need adaptation for non-TypeScript projects:

| Hook | Coupling | Adaptation |
|------|----------|------------|
| pre-write-test-gate | .ts → .test.ts mapping | Add target language test file conventions |
| post-write-hardcode-gate | JS/TS syntax patterns | Add language-specific hard-code patterns |
| post-write-monolith-gate | LOC counting, function regex | Adjust function detection for target language |
| session-test-rules | TypeScript testing pyramid | Replace with target framework conventions |
| write-preflight-stamp | npm test, tsc, eslint | Replace with target build/test/lint commands |
| pr-compliance-gate | tsc --noEmit, eslint | Replace with target type checker and linter |
| precommit-install-gate | Pre-commit config paths | Adjust for target language pre-commit setup |

### Language-Agnostic Modules

All other hooks (zone, budget, role, sprint, receipt, worktree, queue, bootstrap) operate on Git/GitHub metadata only — they work with any language without modification.

### How to Adapt

1. Fork the language-coupled hook file
2. Update file extension patterns (e.g., `.py` → `test_*.py` for Python)
3. Update build/test/lint commands in preflight stamp
4. Update session-test-rules with target framework conventions
5. Register updated hooks in `.claude/settings.json`
