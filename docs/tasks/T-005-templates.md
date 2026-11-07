# T-005: Шаблоны артефактов

| Поле | Значение |
|---|---|
| id | T-005 |
| title | Шаблоны task-card, adr, plan-row |
| role | orchestrator |
| status | done |
| depends_on | T-002 |
| artifacts | `harness/templates/task-card.md`, `harness/templates/adr.md`, `harness/templates/plan-row.md` |
| commit | записан в T-006 |

## Acceptance

- [x] `task-card.md` содержит все поля карточки из `harness/process.md` п. 3.
- [x] `adr.md` — шаблон Architecture Decision Record (контекст, решение, альтернативы, последствия).
- [x] `plan-row.md` — шаблон строки board и правила заполнения.
- [x] Шаблоны не содержат placeholder-мусора, готовы к копированию.

## Log

- 2026-11-07: созданы `harness/templates/task-card.md`, `adr.md`, `plan-row.md`.
