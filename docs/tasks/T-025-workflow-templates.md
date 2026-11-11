# T-025: Workflow and bug templates with the 9-column board

| Field | Value |
|---|---|
| id | T-025 |
| title | Feature/bugfix cards, bug report card, board row, and checkpoint fields |
| workflow | feature |
| stage | P-00 / F-01 |
| role | orchestrator |
| status | done |
| depends_on | T-024 |
| inputs | ADR-003, workflow contracts, shared process |
| artifacts | `harness/templates/task-card-feature.md`, `task-card-bugfix.md`, `bug-card.md`, `plan-row.md`, `checkpoint.md`, `task-card.md` |
| e2e | not applicable (templates) |
| ux | not applicable (templates) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] Feature and bugfix cards expose `workflow`, `stage`, applicability, and checkpoints.
- [x] Bugfix cards add `bug`, `severity`, and `profile`.
- [x] Bug card contains report, triage, root cause, fix, verification, and postmortem sections.
- [x] Board row has `Workflow` and `Bug` columns.
- [x] Checkpoint records workflow and bug link.
- [x] `task-card.md` is a deprecation pointer, not a competing template.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | templates | templates + board schema | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | templates + board schema | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: added/updated templates and board schema.
