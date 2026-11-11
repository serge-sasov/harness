# T-023: ADR-003 and contracts for feature/bugfix workflows

| Field | Value |
|---|---|
| id | T-023 |
| title | Separate feature and bugfix workflows without duplicating harness |
| workflow | feature |
| stage | R-01 |
| role | architect |
| status | done |
| depends_on | T-021 |
| inputs | user decisions, 2.1.0 process, UX/e2e/checkpoint rules |
| artifacts | `docs/architecture/adr-003-feature-bugfix-workflows.md`, `docs/architecture/contracts-workflows-bugfix.md` |
| e2e | not applicable (process design) |
| ux | not applicable (process design) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] ADR records one harness, two workflows, one board, and strict sequencing.
- [x] Alternatives cover separate agent/board sets, waived stages, and issues-only bugs.
- [x] Contracts define task fields, bug card fields/statuses, board columns, and commands.
- [x] Bugfix reproduction/fail-before, minimal fix, and independent QA gates are explicit.
- [x] Escalation triggers and the `hotfix` modifier are documented.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | ADR and contracts | ADR-003 + contracts | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | ADR-003 + contracts | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: recorded user decisions, ADR-003, and the workflow/bug contracts.
