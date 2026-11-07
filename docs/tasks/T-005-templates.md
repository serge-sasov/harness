# T-005: Шаблоны артефактов

| Поле | Значение |
|---|---|
| id | T-005 |
| title | Шаблоны task-card, adr, plan-row |
| role | orchestrator |
| status | pending |
| depends_on | T-002 |
| artifacts | `harness/templates/task-card.md`, `harness/templates/adr.md`, `harness/templates/plan-row.md` |
| commit | — |

## Acceptance

- [ ] `task-card.md` содержит все поля карточки из `harness/process.md` п. 3.
- [ ] `adr.md` — шаблон Architecture Decision Record (контекст, решение, альтернативы, последствия).
- [ ] `plan-row.md` — шаблон строки board и правила заполнения.
- [ ] Шаблоны не содержат placeholder-мусора, готовы к копированию.

## Log

- 2026-11-07: задача создана.
