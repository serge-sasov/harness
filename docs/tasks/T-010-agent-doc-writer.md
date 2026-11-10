# T-010: Sub-agent doc-writer

| Field | Value |
|---|---|
| id | T-010 |
| title | Role sub-agent `doc-writer` (runbook, README, ADR finalization) |
| role | doc-writer |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/doc-writer.md` |
| commit | 876e943 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [x] Permission: edit only `docs/guides/**`, `README.md`, and `docs/tasks/**`; `task: deny`; deny `~/.config/opencode/**`, `D:..Q:`.
- [x] Prompt references `harness/process.md` sections 4-7.
- [x] Style: concise, no duplication, examples and commands included.

## Log

- 2026-11-07: created `harness/agents/doc-writer.md` (README, guides, runbook, ADR finalization).
