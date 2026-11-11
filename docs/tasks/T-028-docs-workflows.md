# T-028: Update README, guide, and solution description for workflows

| Field | Value |
|---|---|
| id | T-028 |
| title | Document feature/bugfix routing, BUG cards, and version 2.2.0 |
| workflow | feature |
| stage | D-01 |
| role | doc-writer |
| status | done |
| depends_on | T-027 |
| inputs | ADR-003, workflow contracts, process/workflow files, commands |
| artifacts | `README.md`, `docs/guides/harness-global.md`, `docs/description/README.md` |
| e2e | not applicable (documentation) |
| ux | not applicable (documentation) |
| issues | - |
| commit | working tree (direct developer update) |

## Acceptance

- [x] README lists workflows, commands, templates, bug registry, and version 2.2.0.
- [x] Guide shows `harness/workflows/`, `docs/bugs/`, new commands, and updated init tree.
- [x] Description explains one harness with two workflows and the bugfix gates.
- [x] Stale `task-card.md` instructions are replaced by feature/bugfix templates.
- [x] No product bugs are directed to `docs/issues/`.
- [x] Markdown links and paths are valid.

## Checkpoints

| ID | Stage | Artifacts | Status | Review file |
|---|---|---|---|---|
| CP-1 | documentation draft | README + guide + description | n/a (direct update) | validated by T-022 |
| CP-F | final acceptance | documentation set | n/a (direct update) | validated by T-022 |

## Blockers

- (none)

## Log

- 2026-11-11: card created; documentation update in progress.
- 2026-11-11: README, guide, and description updated; relative links validated; task completed.
