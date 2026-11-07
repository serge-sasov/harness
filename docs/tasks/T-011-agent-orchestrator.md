# T-011: Sub-agent orchestrator

| Поле | Значение |
|---|---|
| id | T-011 |
| title | Ролевой sub-agent `orchestrator` (план, зависимости, board, приёмка) |
| role | orchestrator |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/orchestrator.md` |
| commit | записан в T-012 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [x] Permission: edit `docs/**` и `README.md`; `task: deny` (сам не вызывает под-агентов; эскалирует пользователю).
- [x] Промпт ссылается на регламент `harness/process.md` п. 3–7.
- [x] Описаны алгоритм ведения board, проверка depends_on, retry-политика, эскалация.

## Log

- 2026-11-07: создан `harness/agents/orchestrator.md` (board, приёмка, диаграмма, коммиты, retry/эскалация).
