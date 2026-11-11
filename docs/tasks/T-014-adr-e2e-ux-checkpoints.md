# T-014: ADR-002 and contracts for e2e, UX, and checkpoints

| Field | Value |
|---|---|
| id | T-014 |
| title | Formalize e2e data, UX artifacts, and user checkpoints |
| role | architect |
| status | done |
| depends_on | T-013 |
| inputs | `docs/description/README.md`, `harness/process.md`, `requirements/initial.txt` |
| artifacts | `docs/architecture/adr-002-harness-e2e-ux-checkpoints.md`, `docs/architecture/contracts-e2e-ux-checkpoints.md` |
| e2e | required (contract for `UC-E2E-NNN` and `harness-e2e/1`) |
| ux | required (contract for `docs/ux/` artifacts) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] ADR-002 records context, decision, alternatives, consequences, and links.
- [x] Contract defines Markdown `UC-E2E-NNN` fields and YAML `harness-e2e/1`.
- [x] Contract defines `docs/ux/` artifacts, screen IDs, and prototype rules.
- [x] Contract defines checkpoint statuses, transitions, and mandatory `CP-F`.
- [x] Contracts align with `harness/process.md` and the templates.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | ADR + contracts | ADR-002, contracts | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | all artifacts | n/a (direct update) | validated by T-022 |

## Log

- 2026-11-11: created ADR-002 and the e2e/UX/checkpoint contract as part of the 2.1.0 update.
