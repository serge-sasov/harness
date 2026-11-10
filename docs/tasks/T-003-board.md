# T-003: Board and task cards

| Field | Value |
|---|---|
| id | T-003 |
| title | Shared plan (board) + cards for all tasks |
| role | orchestrator |
| status | done |
| depends_on | T-002 |
| artifacts | `docs/plan.md`, `docs/tasks/T-001..T-013-*.md` |
| commit | c621012 |

## Acceptance

- [x] `docs/plan.md` contains T-001..T-013 rows with columns ID, task, role, dependencies, status, artifacts, commit.
- [x] Each task has a card with fields id, title, role, status, depends_on, acceptance, artifacts, blockers, log.
- [x] Board statuses match `git log` at acceptance time.

## Log

- 2026-11-07: created `docs/plan.md` (board, legend, rules) and 13 cards in `docs/tasks/`.
