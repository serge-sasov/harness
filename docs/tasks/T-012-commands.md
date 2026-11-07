# T-012: Команды opencode

| Поле | Значение |
|---|---|
| id | T-012 |
| title | Команды harness: role-run, board-update, board-report |
| role | orchestrator |
| status | done |
| depends_on | T-006, T-007, T-008, T-009, T-010, T-011 |
| artifacts | `harness/commands/harness-run.md`, `harness/commands/harness-board-update.md`, `harness/commands/harness-board-report.md` |
| commit | cbf393f |

## Acceptance

- [x] Каждая команда — MD-файл с frontmatter (`description`, при необходимости `agent`/`model`) и телом-шаблоном.
- [x] `role-run` принимает ID задачи (`$ARGUMENTS`), проверяет depends_on, ставит in_progress.
- [x] `board-update` обновляет plan.md, карточку, activity.puml, перерендеривает SVG, коммитит.
- [x] `board-report` выводит сводку статусов и блокеров.

## Log

- 2026-11-07: созданы `harness/commands/role-run.md`, `board-update.md`, `board-report.md`.
- 2026-11-07 (global harness): команды переименованы в `harness-run`, `harness-board-update`, `harness-board-report`; актуальные файлы — `harness/commands/harness-*.md`.
