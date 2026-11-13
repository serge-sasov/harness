# T-034: Release harness 2.5.0

| Field | Value |
|---|---|
| id | T-034 |
| title | Version 2.5.0: install/init/doctor, pilot sync, release |
| workflow | feature |
| stage | F-01 |
| role | orchestrator |
| status | done |
| hold | false |
| depends_on | T-033 |
| inputs | T-033 docs/scripts, `harness/version.json` |
| artifacts | `install.ps1`, `init.ps1`, `doctor.ps1`, `version.json`, global install, ai-task-tracker sync |
| e2e | not applicable (installation/health checks) |
| ux | not applicable |
| chunks | install/init, doctor, version/docs, pilot re-init |
| budget | 8/20/60 (Markdown); 12/40/65 (code) |
| base_commit | - |
| usage | n/a |
| issues | - |
| commit | working tree |

## Acceptance

- [x] `install.ps1` copies agents/commands/skills/templates/scripts/checks and backs up before overwriting.
- [x] `init.ps1` creates `harness/checks`, `docs/evidence`, and `docs/metrics`, and installs the 2.5.0 scripts/checks.
- [x] `doctor.ps1` checks engine self-test, registry completeness, allow patterns, project checks/scripts, approved checkpoints without checks JSON, and token attribution.
- [x] `version.json` is 2.5.0 with `/harness-stage-done`; global install and ai-task-tracker re-init completed.
- [x] Doctor reports no critical problems globally, in the harness repo, and in ai-task-tracker.
- [x] T-030 CP-F remains `awaiting_review`; 2.5.0 is committed in the harness repo.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | release | install/init/doctor | - | approved | - |
| CP-F | final acceptance | all task artifacts | - | approved | - |

## Blockers

- none

## Log

- 2026-11-13: install/init/doctor wired, version 2.5.0, global install and ai-task-tracker re-init done; doctor passed with only pre-existing RAG-timeout and token-attribution warnings.
