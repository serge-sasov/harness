# Board row template (`docs/plan.md`)

| ID | Workflow | Task | Role | Dependencies | Status | Bug | Artifacts | Commit |
|---|---|---|---|---|---|---|---|---|
| T-XXX | feature | Short title | role | T-YYY | pending | - | path/to/artifacts | - |

## Filling rules

- `ID` ascending/immutable; `Task` short, details in the card. Task IDs are
  global `T-XXX`; product bugs use `BUG-XXX` in `docs/bugs/`.
- `Workflow`: `feature` or `bugfix`; legacy rows without a value mean `feature`.
- `Role`: orchestrator, analyst, ux-designer, architect, coder, qa, or
  doc-writer.
- `Dependencies`: comma-separated, `-` if none; all must be `done` before start.
- `Status`: `pending` | `in_progress` | `awaiting_review` | `done` | `failed` |
  `blocked`; colors mirror `docs/activity.puml` (process section 9).
- `Bug`: `BUG-XXX` for bugfix tasks, `-` for feature tasks.
- `awaiting_review` is an active status: it blocks other tasks until the user
  approves or requests changes.
- `Artifacts`: relative to the repo root. `Commit`: final task hash; checkpoint
  commits are recorded in the card.
- `e2e` / `ux` applicability, workflow, stage, and the checkpoint list live in
  the task card, not on the board.
