# T-007: Sub-agent architect

| Поле | Значение |
|---|---|
| id | T-007 |
| title | Ролевой sub-agent `architect` (ADR, компоненты, контракты, PlantUML) |
| role | architect |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/architect.md` |
| commit | 061f8e5 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [x] Permission: edit только `docs/architecture/**` и `docs/tasks/**`; `task: deny`; deny на `~/.config/opencode/**`, `D:..Q:`.
- [x] Промпт ссылается на регламент `harness/process.md` п. 4–7.
- [x] Определены вход (аналитика, требования) и выход (ADR, .puml, контракты интерфейсов).
- [x] Разрешён MCP `plantuml-render` (check_syntax + render_diagram).

## Log

- 2026-11-07: создан `harness/agents/architect.md` (ADR, схемы, контракты, контроль PlantUML через MCP).
