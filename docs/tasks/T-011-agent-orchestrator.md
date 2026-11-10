# T-011: Sub-agent orchestrator

| Field | Value |
|---|---|
| id | T-011 |
| title | Role sub-agent `orchestrator` (plan, dependencies, board, acceptance) |
| role | orchestrator |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/orchestrator.md` |
| commit | e021349 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [x] Permission: edit `docs/**` and `README.md`; `task: deny` (does not call subagents; escalates to the user).
- [x] Prompt references `harness/process.md` sections 3-7.
- [x] Board algorithm, `depends_on` check, retry policy, and escalation are described.

## Log

- 2026-11-07: created `harness/agents/orchestrator.md` (board, acceptance, diagram, commits, retry/escalation).
