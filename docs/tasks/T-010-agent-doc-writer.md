# T-010: Sub-agent doc-writer

| Поле | Значение |
|---|---|
| id | T-010 |
| title | Ролевой sub-agent `doc-writer` (runbook, README, финализация ADR) |
| role | doc-writer |
| status | pending |
| depends_on | T-005 |
| artifacts | `harness/agents/doc-writer.md` |
| commit | — |

## Acceptance

- [ ] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [ ] Permission: edit только `docs/guides/**`, `README.md` и `docs/tasks/**`; `task: deny`; deny на `~/.config/opencode/**`, `D:..Q:`.
- [ ] Промпт ссылается на регламент `harness/process.md` п. 4–7.
- [ ] Определён стиль: кратко, без дублей, с примерами и командами.

## Log

- 2026-11-07: задача создана.
