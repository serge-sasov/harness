# T-006: Sub-agent analyst

| Поле | Значение |
|---|---|
| id | T-006 |
| title | Ролевой sub-agent `analyst` (сбор требований, RAG-анализ) |
| role | analyst |
| status | pending |
| depends_on | T-005 |
| artifacts | `harness/agents/analyst.md` |
| commit | — |

## Acceptance

- [ ] Frontmatter: `mode: subagent`, `model: ollama-metrics/qwen3.8:27b-64k`, `temperature: 0.1`.
- [ ] Permission: edit только `docs/analysis/**` и `docs/tasks/**` (лог своей задачи); `task: deny`; deny на `~/.config/opencode/**`, `D:..Q:`.
- [ ] Промпт ссылается на регламент `harness/process.md` п. 4–7.
- [ ] Определены вход (карточка задачи, требования, RAG) и выход (docs/analysis/*.md).
- [ ] Указан инструментарий: `local-rag_rag_search`, `local-rag_rag_context`.

## Log

- 2026-11-07: задача создана.
