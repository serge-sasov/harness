# T-007: Sub-agent architect

| Field | Value |
|---|---|
| id | T-007 |
| title | Role sub-agent `architect` (ADR, components, contracts, PlantUML) |
| role | architect |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/architect.md` |
| commit | 061f8e5 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [x] Permission: edit only `docs/architecture/**` and `docs/tasks/**`; `task: deny`; deny `~/.config/opencode/**`, `D:..Q:`.
- [x] Prompt references `harness/process.md` sections 4-7.
- [x] Inputs (analysis, requirements) and outputs (ADR, .puml, interface contracts) are defined.
- [x] MCP `plantuml-render` is allowed (`check_syntax` + `render_diagram`).

## Log

- 2026-11-07: created `harness/agents/architect.md` (ADR, diagrams, contracts, PlantUML control via MCP).
