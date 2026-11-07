# T-003: Board и карточки задач

| Поле | Значение |
|---|---|
| id | T-003 |
| title | Общий план (board) + карточки всех задач |
| role | orchestrator |
| status | done |
| depends_on | T-002 |
| artifacts | `docs/plan.md`, `docs/tasks/T-001..T-013-*.md` |
| commit | записан в T-004 |

## Acceptance

- [x] `docs/plan.md` содержит строки T-001..T-013 с колонками ID, задача, роль, зависимости, статус, артефакты, коммит.
- [x] Для каждой задачи создана карточка с полями id, title, role, status, depends_on, acceptance, artifacts, blockers, log.
- [x] Статусы в board согласованы с git log на момент приёмки.

## Log

- 2026-11-07: создан `docs/plan.md` (board, легенда, правила) и 13 карточек в `docs/tasks/`.
