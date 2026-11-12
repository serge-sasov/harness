# T-030: Harness 2.3.0 - context budgets, chunking, and self-sub-sessions

| Field | Value |
|---|---|
| id | T-030 |
| title | Harness 2.3.0: generation budgets, A-02/code chunking, self-sub-sessions |
| workflow | feature |
| stage | implementation |
| role | orchestrator |
| status | awaiting_review |
| depends_on | T-029 |
| inputs | ISSUE-20261112-094931, T-003 evidence, `harness/process.md` |
| artifacts | process, templates, agents, install/doctor/uninstall, budget and e2e validators, version/docs |
| e2e | not applicable (harness tooling; validators tested on T-003 data) |
| ux | not applicable |
| chunks | process/templates, agents/permissions, installer/doctor, scripts, docs/version |
| budget | 8/20/60 (Markdown); 6/15/60 (YAML); 12/40/65 (code) |
| issues | ISSUE-20261112-094931; ISSUE-20261111-100017 (RAG sync timeout, pre-existing) |
| commit | pending |

## Goal

Prevent another T-003-style context exhaustion: bound each generation, decompose
large stages, and allow analyst/coder self-sub-sessions for chunks without
opening cross-role delegation.

## Acceptance

- [x] `harness/process.md` has generation/context budgets, A-02 chunking,
      per-chunk attempts, compaction handoff, and the self-sub-session exception.
- [x] Task-card and e2e templates carry `chunks`/`budget` and chunking notes.
- [x] Analyst/coder prompts have self `task` allow and budget rules; other roles
      stay `task: deny`.
- [x] `install.ps1` sets top-level `subagent_depth: 2` with backup/JSON
      validation; `doctor.ps1` checks depth, self-allows, and cross-role allows.
- [x] `check-budget.ps1` and `validate-e2e-data.py` added and exercised on T-003
      data (validator: 8 use cases, 24 links, 0 errors).
- [x] Version/docs bumped to 2.3.0; global install and ai-task-tracker sync done;
      doctor reports no critical problems.
- [ ] Runtime self-sub-session smoke test after restarting opencode.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-F | final acceptance | all task artifacts | awaiting_review | `docs/checkpoints/T-030-CP-F.md` |

## Blockers

- Runtime smoke test requires an opencode restart to load `subagent_depth: 2`.

## Log

- 2026-11-12: implemented budgets/chunking/self-sessions, installer/doctor checks,
  validators, docs/version; installed globally and synced ai-task-tracker.
- 2026-11-12: `doctor.ps1` passed all new checks; T-003 YAML validated with 0
  errors. `check-budget.ps1` flags the 28.1 KB T-003 YAML as above the 15 KB
  YAML session budget, documenting the original incident.
- 2026-11-12: `opencode debug agent harness-analyst` confirms the resolved task
  permission keeps `"*": "deny"` and adds `harness-analyst: "allow"`.
- 2026-11-12 (post-restart, depth 2): `task` self-sub-session of `harness-analyst`
  spawned one child (`harness-analyst`) that replied `CHILD_OK`; no
  grandchildren or other roles. Self-sub-session verified working.
