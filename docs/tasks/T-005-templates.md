# T-005: Artifact templates

| Field | Value |
|---|---|
| id | T-005 |
| title | task-card, adr, plan-row templates |
| role | orchestrator |
| status | done |
| depends_on | T-002 |
| artifacts | `harness/templates/task-card.md`, `harness/templates/adr.md`, `harness/templates/plan-row.md` |
| commit | recorded in T-006 |

## Acceptance

- [x] `task-card.md` contains all card fields from `harness/process.md` section 3.
- [x] `adr.md` is an Architecture Decision Record template (context, decision, alternatives, consequences).
- [x] `plan-row.md` is a board row template with filling rules.
- [x] Templates contain no placeholder junk and are ready to copy.

## Log

- 2026-11-07: created `harness/templates/task-card.md`, `adr.md`, `plan-row.md`.
