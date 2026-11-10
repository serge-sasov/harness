# T-002: Process rules

| Field | Value |
|---|---|
| id | T-002 |
| title | Unified production process rules |
| role | orchestrator |
| status | done |
| depends_on | T-001 |
| artifacts | `harness/process.md` |
| commit | 9d713d8 |

## Acceptance

- [x] Role models are fixed (role -> Ollama model table).
- [x] Board, task cards, statuses, and allowed transitions are described.
- [x] Task lifecycle and the mandatory artifact update order are described.
- [x] Git discipline is fixed: a commit after each task, message format.
- [x] Error handling (failed/blocked, max 3 retries) and prohibitions are described.

## Log

- 2026-11-07: created `harness/process.md` (9 sections); commit `9d713d8`.
