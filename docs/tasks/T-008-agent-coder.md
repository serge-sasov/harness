# T-008: Sub-agent coder

| Field | Value |
|---|---|
| id | T-008 |
| title | Role sub-agent `coder` (implementation, tests, CI/CD) |
| role | coder |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/coder.md` |
| commit | e4a4686 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/tiel-coder:35b-a3b-mtp-128k-text`, `temperature: 0.1`.
- [x] Permission: modeled on `local-coder.md` (whitelist build/test/lint, deny push/commit/rm); edit only `src/`, `tests/`, `scripts/`, `Dockerfile`, `Makefile`, `docs/tasks/**`.
- [x] Prompt references `harness/process.md` sections 4-7.
- [x] Inputs (ADR/contracts) and outputs (code, tests, report) are defined.

## Log

- 2026-11-07: created `harness/agents/coder.md` (bash whitelist, write area, test/CI rules, prohibitions).
