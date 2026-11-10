# T-013: Full-cycle smoke test

| Field | Value |
|---|---|
| id | T-013 |
| title | Full-cycle run on a pilot task |
| role | qa |
| status | done |
| depends_on | T-012 |
| artifacts | `docs/analysis/`, `docs/architecture/`, `docs/qa/` (pilot) |
| commit | fb145b6 |

## Acceptance

- [x] The analyst produces `docs/analysis/pilot-requirements.md` for the pilot task ("Mini-CRUD service").
- [x] The architect produces `docs/architecture/pilot-adr.md` + `docs/architecture/pilot-components.puml` (valid, renders).
- [x] QA writes `docs/qa/pilot-review.md` with an accept/reject verdict.
- [x] The board and activity diagram are updated after the cycle; a commit is made.
- [x] Role prompts are sufficiently deterministic (the result matches acceptance).

## Log

- 2026-11-07: roles executed per `harness/agents/*.md`; created requirements (R-001..R-006, NFR-1..3), ADR-001 with alternatives, a component diagram (SVG rendered), and a QA review with verdict `accept` (2 minor findings).
- 2026-11-07: agents were registered per project in `.opencode/agents/` (copies from `harness/agents/`); actual subagent calls became available after an opencode restart - in the current session the roles were executed from the same prompts.
- 2026-11-07 (global harness): roles moved to the global `harness-*` installation; project copies in `.opencode/agents/` removed to avoid duplicate IDs and permission-gating bypass.
