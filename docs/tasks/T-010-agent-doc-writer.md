# T-010: Sub-agent doc-writer

| Поле | Значение |
|---|---|
| id | T-010 |
| title | Ролевой sub-agent `doc-writer` (runbook, README, финализация ADR) |
| role | doc-writer |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/doc-writer.md` |
| commit | 876e943 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [x] Permission: edit только `docs/guides/**`, `README.md` и `docs/tasks/**`; `task: deny`; deny на `~/.config/opencode/**`, `D:..Q:`.
- [x] Промпт ссылается на регламент `harness/process.md` п. 4–7.
- [x] Определён стиль: кратко, без дублей, с примерами и командами.

## Log

- 2026-11-07: создан `harness/agents/doc-writer.md` (README, гайды, runbook, финализация ADR).
