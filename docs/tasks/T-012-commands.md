# T-012: Команды opencode

| Поле | Значение |
|---|---|
| id | T-012 |
| title | Команды harness: role-run, board-update, board-report |
| role | orchestrator |
| status | done |
| depends_on | T-006, T-007, T-008, T-009, T-010, T-011 |
| artifacts | `harness/commands/role-run.md`, `harness/commands/board-update.md`, `harness/commands/board-report.md` |
| commit | записан в T-013 |

## Acceptance

- [x] Каждая команда — MD-файл с frontmatter (`description`, при необходимости `agent`/`model`) и телом-шаблоном.
- [x] `role-run` принимает ID задачи (`$ARGUMENTS`), проверяет depends_on, ставит in_progress.
- [x] `board-update` обновляет plan.md, карточку, activity.puml, перерендеривает SVG, коммитит.
- [x] `board-report` выводит сводку статусов и блокеров.

## Log

- 2026-11-07: созданы `harness/commands/role-run.md`, `board-update.md`, `board-report.md`.
