# T-044: Templates, documentation, and release 3.0.0

| Field | Value |
|---|---|
| id | T-044 |
| title | Chunk-aware templates, documentation, and harness 3.0.0 release |
| workflow | feature |
| stage | D-01 |
| role | doc-writer |
| status | done |
| hold | false |
| depends_on | T-042, T-043 |
| inputs | `docs/architecture/adr-006-recursive-decomposition.md`, `harness/process.md`, `harness/checks/feature.json`, `harness/checks/bugfix.json`, `harness/templates/`, `README.md`, `docs/guides/harness-global.md`, `CHANGELOG.md`, `harness/version.json`, `harness/scripts/install.ps1` |
| artifacts | `harness/templates/task-card-feature.md`, `harness/templates/task-card-bugfix.md`, `harness/templates/plan-row.md`, `harness/templates/chunk-ledger.md`, `README.md`, `docs/guides/harness-global.md`, `CHANGELOG.md`, `harness/version.json`, `docs/description/`, `docs/manual/`, global install |
| e2e | not applicable (documentation) |
| ux | not applicable |
| chunks | A: card/plan templates and the ledger template; B: README + guide + manual/description; C: changelog, version, install and doctor run |
| budget | 8/20/60 (Markdown) |
| base_commit | pending |
| usage | - |
| issues | - |
| commit | pending |

## Acceptance

- [ ] `task-card-feature.md` and `task-card-bugfix.md` replace the free-text `chunks` description with a chunk plan that references `docs/chunks/T-XXX.json` and states the granularity, the depth policy, and the chunk check ids.
- [ ] The `budget` field documents the extended knobs (`max_write_kb`, `max_session_kb`, `context_stop_pct`, `max_turns`, `max_input_tokens`, `max_wall_min`).
- [ ] `harness/templates/chunk-ledger.md` is the canonical schema reference and matches `chunk-validate.py` exactly.
- [ ] `plan-row.md` and the board schema mention that chunk progress lives in the ledger, not in a new board column.
- [ ] `README.md` and `docs/guides/harness-global.md` describe the decomposition model, the depth policy, the stop/resume contract, and the pilot measurements.
- [ ] `CHANGELOG.md` records 3.0.0 with the full changed-file list, and `harness/version.json` is 3.0.0.
- [ ] `docs/description/` and `docs/manual/` are regenerated and their HTML rebuilt.
- [ ] The global installation matches 3.0.0 and `/harness-doctor` reports no critical problem.

## Checkpoints

| ID | Stage | Artifacts | Checks | Status | Review file |
|---|---|---|---|---|---|
| CP-1 | templates and docs | templates, README, guide | n/a | approved | `docs/checkpoints/T-044-CP-1.md` |
| CP-F | final acceptance | all task artifacts | n/a | approved | `docs/checkpoints/T-044-CP-F.md` |

## Blockers

- none

## Log

- 2026-11-14: card created for T-044 (phase B, step 3).
- 2026-11-14: card/plan/chunk templates, README, guide, description, manual updated; both HTML builds ran; CHANGELOG 3.0.0 and version.json 3.0.0; global install and doctor clean (project version matches global). CP-1 and CP-F approved (harness-core task: machine checks n/a).
