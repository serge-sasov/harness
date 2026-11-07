# T-006: Sub-agent analyst

| Поле | Значение |
|---|---|
| id | T-006 |
| title | Ролевой sub-agent `analyst` (сбор требований, RAG-анализ) |
| role | analyst |
| status | done |
| depends_on | T-005 |
| artifacts | `harness/agents/analyst.md` |
| commit | 9ad3ec9 |

## Acceptance

- [x] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [x] Permission: edit только `docs/analysis/**` и `docs/tasks/**` (лог своей задачи); `task: deny`; deny на `~/.config/opencode/**`, `D:..Q:`.
- [x] Промпт ссылается на регламент `harness/process.md` п. 4–7.
- [x] Определены вход (карточка задачи, требования, RAG) и выход (docs/analysis/*.md).
- [x] Указан инструментарий: `local-rag_rag_search`, `local-rag_rag_context`.

## Log

- 2026-11-07: создан `harness/agents/analyst.md` (роль, зона записи, RAG-инструменты, запреты).
