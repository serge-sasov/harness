# T-006: Sub-agent analyst

| Field | Value |
|---|---|
| id | T-006 |
| title | Role sub-agent `analyst` (requirements, RAG analysis) |
| role | analyst |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/analyst.md` |
| commit | 9ad3ec9 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [x] Permission: edit only `docs/analysis/**` and `docs/tasks/**` (own task log); `task: deny`; deny `~/.config/opencode/**`, `D:..Q:`.
- [x] Prompt references `harness/process.md` sections 4-7.
- [x] Inputs (task card, requirements, RAG) and outputs (`docs/analysis/*.md`) are defined.
- [x] Tools: `local-rag_rag_search`, `local-rag_rag_context`.

## Log

- 2026-11-07: created `harness/agents/analyst.md` (role, write area, RAG tools, prohibitions).
