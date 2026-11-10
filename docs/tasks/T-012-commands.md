# T-012: opencode commands

| Field | Value |
|---|---|
| id | T-012 |
| title | Harness commands: role-run, board-update, board-report |
| role | orchestrator |
| status | done |
| depends_on | T-006, T-007, T-008, T-009, T-010, T-011 |
| artifacts | `harness/commands/harness-run.md`, `harness/commands/harness-board-update.md`, `harness/commands/harness-board-report.md` |
| commit | cbf393f |

## Acceptance

- [x] Each command is an MD file with frontmatter (`description`, optional `agent`/`model`) and a template body.
- [x] `role-run` accepts a task ID (`$ARGUMENTS`), checks `depends_on`, and sets `in_progress`.
- [x] `board-update` updates plan.md, the card, activity.puml, re-renders SVG, and commits.
- [x] `board-report` prints a status and blocker summary.

## Log

- 2026-11-07: created `harness/commands/role-run.md`, `board-update.md`, `board-report.md`.
- 2026-11-07 (global harness): commands renamed to `harness-run`, `harness-board-update`, `harness-board-report`; current files are `harness/commands/harness-*.md`.
