# Board row template (`docs/plan.md`)

| ID | Workflow | Task | Role | Dependencies | Status | Bug | Artifacts | Usage | Commit |
|---|---|---|---|---|---|---|---|---|---|
| T-XXX | feature | Short title | role | T-YYY | pending | - | path/to/artifacts | - | - |

## Filling rules

- `ID` ascending/immutable; `Task` short, details in the card. Task IDs are
  global `T-XXX`; product bugs use `BUG-XXX` in `docs/bugs/`.
- `Workflow`: `feature` or `bugfix`; legacy rows without a value mean `feature`.
- `Role`: orchestrator, analyst, ux-designer, architect, coder, qa, or
  doc-writer.
- `Dependencies`: comma-separated, `-` if none; all must be `done` before start.
- `Status`: `pending` | `in_progress` | `awaiting_review` | `done` | `failed` |
  `blocked`. The board is authoritative; activity colors are rendered from it
  and never used to determine status (process section 9).
- `Bug`: `BUG-XXX` for bugfix tasks, `-` for feature tasks.
- `awaiting_review` is an active status: it blocks other tasks until the user
  approves or requests changes.
- `Artifacts`: relative to the repo root; UX prototype rows use
  `docs/ux/prototype/<slug>/index.html`, `uc-e2e-*.html`, `assets/*`.
- `Usage`: measured task tokens written by `stage-done.ps1`
  (`in=... out=... cr=... ratio=...x min=...`); `-` before the first checkpoint.
- `Commit`: latest task hash (checkpoint snapshot or closure) written by
  `stage-done.ps1`/`board-update.ps1`; the full checkpoint history is in the
  card log.
- `e2e` / `ux` applicability, workflow, stage, and the checkpoint list live in
  the task card, not on the board.
