# T-024: Split process into shared rules and workflow files

| Field | Value |
|---|---|
| id | T-024 |
| title | Shared process rules plus feature and bugfix stage definitions |
| workflow | feature |
| stage | P-00 / F-01 |
| role | orchestrator |
| status | done |
| depends_on | T-023 |
| inputs | ADR-003, workflow contracts, 2.1.0 process |
| artifacts | `harness/process.md`, `harness/workflows/feature.md`, `harness/workflows/bugfix.md` |
| e2e | not applicable (process design) |
| ux | not applicable (process design) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] Shared rules cover installation, roles, routing, board, checkpoints, artifacts, git, errors, and issues.
- [x] Feature stages and task graph are defined once in `feature.md`.
- [x] Bugfix stages, gates, escalation, and P0/P1 postmortem are defined once in `bugfix.md`.
- [x] One-active-task invariant applies across both workflows.
- [x] Product bugs and harness issues are separated.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | process split | process + workflow files | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | process + workflow files | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: rewrote `process.md`; added `feature.md` and `bugfix.md`.
