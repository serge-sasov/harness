# T-030 CP-F: final acceptance

| Field | Value |
|---|---|
| task | T-030 |
| checkpoint | CP-F |
| status | awaiting_review |
| date | 2026-11-12 |
| reviewer | user |

## Artifacts

- `harness/process.md`: budgets, A-02/code chunking, self-sub-sessions,
  per-chunk attempts, compaction handoff.
- `harness/templates/task-card-feature.md`, `task-card-bugfix.md`,
  `e2e-use-case.md`, `e2e-test-data.yaml`.
- `harness/agents/harness-analyst.md`, `harness-coder.md`,
  `harness-orchestrator.md`, `harness-qa.md`, `harness.md`.
- `harness/scripts/install.ps1`, `doctor.ps1`, `uninstall.ps1`,
  `check-budget.ps1`, `validate-e2e-data.py`.
- `harness/version.json` (2.3.0), `README.md`,
  `docs/guides/harness-global.md`, `docs/description/README.md`.

## Verification

- `install.ps1`: `subagent_depth` set to 2; config JSON valid.
- `opencode debug agent harness-analyst`: resolved task permissions include
  agent-level `"*": "deny"` and `harness-analyst: "allow"`.
- `doctor.ps1`: all new checks pass; only the pre-existing local-rag timeout
  warning remains.
- 2026-11-12 10:09 (post-restart, depth 2): `task` self-sub-session of
  `harness-analyst` spawned one child (`harness-analyst`), which replied
  `CHILD_OK`; no grandchildren/other roles.
- `validate-e2e-data.py` on T-003: 8 use cases, 24 requirement links, 0 errors.
- `check-budget.ps1` on T-003 YAML: 28.1 KB, over the 15 KB session budget; this
  is expected evidence of the oversized artifact that caused the incident.
- ai-task-tracker `init.ps1 -Force`: synced process/templates/scripts and version
  2.3.0; T-003 card and board preserved.
- Pending: restart opencode, then run a root -> analyst -> analyst permission
  smoke test to confirm depth 2 and self-allow.

## User decision

- pending: approve CP-F or request changes.
