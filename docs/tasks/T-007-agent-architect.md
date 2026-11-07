# T-007: Sub-agent architect

| Поле | Значение |
|---|---|
| id | T-007 |
| title | Ролевой sub-agent `architect` (ADR, компоненты, контракты, PlantUML) |
| role | architect |
| status | pending |
| depends_on | T-005 |
| artifacts | `harness/agents/architect.md` |
| commit | — |

## Acceptance

- [ ] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [ ] Permission: edit только `docs/architecture/**` и `docs/tasks/**`; `task: deny`; deny на `~/.config/opencode/**`, `D:..Q:`.
- [ ] Промпт ссылается на регламент `harness/process.md` п. 4–7.
- [ ] Определены вход (аналитика, требования) и выход (ADR, .puml, контракты интерфейсов).
- [ ] Разрешён MCP `plantuml-render` (check_syntax + render_diagram).

## Log

- 2026-11-07: задача создана.
