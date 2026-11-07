---
description: "Явный запуск задачи harness T-XXX (только при наличии harness/process.md)"
agent: harness
---

Выполни задачу `$ARGUMENTS` по регламенту `harness/process.md`.

Сначала проверь наличие `harness/process.md` и `docs/plan.md`. Если их нет —
остановись и предложи выполнить `/harness-init`.

Алгоритм:

1. Прочитай `docs/plan.md` и карточку `docs/tasks/$ARGUMENTS-*.md`.
2. Проверь `depends_on`: все предшествующие задачи должны быть `done`.
   Если нет — стоп, отчёт о блокировке, статусы не менять.
3. Делегируй `harness-orchestrator`: перевод задачи в `in_progress`, обновление
   `docs/plan.md`, карточки, `docs/activity.puml`, перерендер
   `docs/activity.svg` через MCP `plantuml-render`. Коммит на этом шаге не делать.
4. Определи роль из карточки и вызови соответствующего субагента через `task`:
   `harness-orchestrator` | `harness-analyst` | `harness-architect` |
   `harness-coder` | `harness-qa` | `harness-doc-writer`.
   В промпте передай: ID задачи, путь к карточке, критерии `acceptance`, ссылки
   на входные артефакты, требования регламента пп. 4–7.
5. Делегируй `harness-orchestrator` приёмку и закрытие задачи:
   - при успехе — `done`, обновление артефактов, `git add` + `git commit`;
   - при провале — `failed`, причина в `Blockers`; до 3 попыток исправления,
     затем `blocked` и эскалация пользователю.
6. Отчёт: статус, коммит, разблокированные задачи, блокеры.

Ограничения: не редактируй файлы сам; не вызывай роли вне списка harness;
не делай `git push`, `git tag`, `git reset`, `git rebase`.
