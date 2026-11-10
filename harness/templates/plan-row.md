# Board row template (`docs/plan.md`)

| ID | Task | Role | Dependencies | Status | Artifacts | Commit |
|---|---|---|---|---|---|---|
| T-XXX | Short title | role | T-YYY | pending | path/to/artifacts | - |

## Filling rules

- `ID` ascending/immutable; `Task` short, details in the card.
- `Role`: orchestrator, analyst, architect, coder, qa, or doc-writer.
- `Dependencies`: comma-separated, `-` if none; all must be `done` before start.
- `Status`: `pending` | `in_progress` | `done` | `failed` | `blocked`; colors mirror `docs/activity.puml` (process section 5).
- `Artifacts`: relative to the repo root. `Commit`: task hash; record it in the next task to avoid history rewrite.
