# T-009: Sub-agent qa

| Field | Value |
|---|---|
| id | T-009 |
| title | Role sub-agent `qa` (code/diagram review, tests) |
| role | qa |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/qa.md` |
| commit | 95b3949 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/tiel-coder:35b-a3b-mtp-128k-vision`, `temperature: 0.1`.
- [x] Permission: edit only `docs/qa/**` and `docs/tasks/**`; read the whole project; bash read-only (git status/diff/log, test runners); `task: deny`.
- [x] Prompt references `harness/process.md` sections 4-7.
- [x] Vision scenario: read PlantUML/SVG/screenshots to verify diagrams.
- [x] Verdict right: `accept` / `reject` with a mandatory findings list.

## Log

- 2026-11-07: created `harness/agents/qa.md` (review, vision diagram checks, accept/reject verdict, severity).
